using Distributed, ElasticClusterManager, Sockets
using NetworkInterfaceControllers

# Sane filtering
import Base: filter, Fix1
filter(f::Function)::Function = Fix1(filter, f)

# Get name of the HSN0 network interface
interfaces = NetworkInterfaceControllers.get_interface_data(IPv4)
# Future versions of the NetworkInterfaceControllers package will be able to
# load balance over different network controllers on the same node
hsn0 = filter(
    x->(startswith(x.name, "hsn0") && x.version==:v4), interfaces
) |> first
slingshot_name = getnameinfo(hsn0.ip)

# Initialize the elastic worker, and print debug information
em = ElasticManager(addr=hsn0.ip, topology=:master_worker, port=9009)
# Inject the new network interface-detection logic into the connection string
cc = replace(ElasticClusterManager.get_connect_cmd(em),
    "import ElasticClusterManager" => """
    using ElasticClusterManager, NetworkInterfaceControllers, Sockets;
    hsn0 = filter(
        x->(startswith(x.name,"hsn0") && x.version==:v4),
        NetworkInterfaceControllers.get_interface_data(IPv4)
    ) |> first;
    Sockets.getipaddr() = hsn0.ip; Sockets.getipaddrs() = [hsn0.ip]
"""
)
# clean up the connection string, because we're not savages
cc = replace(
    cc, "\n        " => " ", "\n    " => " ", "\n" => " ", "    " => ""
)

@info "Starting elastic manager" hsn0 slingshot_name em cc

NWORKERS = 2

# launch workers
@async run(`srun -n $NWORKERS bash -c $(cc)`)

# wait for them to connect
while nworkers()<NWORKERS
    @warn "Waiting for workers to connect" nworkers()
    sleep(1)
end

@info "Connections established" nworkers()

# test transfer
@info "Running basic transfer test"
y = rand(Float32, 4*1024^2)
for i=1:20
    @time @everywhere x = $y
end
