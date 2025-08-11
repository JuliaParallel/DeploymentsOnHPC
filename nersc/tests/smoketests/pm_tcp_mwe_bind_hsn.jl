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
while nworkers() < NWORKERS
    @warn "Waiting for workers to connect" nworkers() NWORKERS
    sleep(1)
end

@info "Connections established" nworkers()

# Test transfer
@info "Running basic transfer test"
y = rand(Float32, 4*1024^2)
for i=1:20
    @time @everywhere x = $y
end

# Test channels
@info "Running basic channel test"
@everywhere function do_work(input_channel, output_channel, worker_id)
    println("Worker $worker_id starting work...")
    
    # Process items from input channel
    while true
        try
            # Get work item from input channel
            item = take!(input_channel)
            
            if item == :stop
                println("Worker $worker_id received stop signal")
                break
            end
            
            # Do some computation
            result = item^2 + worker_id
            sleep(0.5)  # Simulate work
            
            # Send result to output channel
            put!(output_channel, (worker_id, item, result))
            println("Worker $worker_id processed $item -> $result")
            
        catch e
            if isa(e, InvalidStateException)
                println("Worker $worker_id: Channel closed")
                break
            else
                rethrow(e)
            end
        end
    end
    
    println("Worker $worker_id finished")
end

# Create remote channels
# Channel from worker 1 to worker 2
channel_1_to_2 = RemoteChannel(()->Channel{Any}(10), 2)
# Channel for collecting results on main process
result_channel = RemoteChannel(()->Channel{Any}(20), 1)

@info "Starting perpetual 'do_work' on worker 2"
worker_2_task = @spawnat 2 do_work(channel_1_to_2, result_channel, 2)

@info "Start work by feeding 'channel_1_to_2' channel on worker 1 "
worker_1_task = @spawnat 1 begin
    println("Worker 1 sending work items...")
    
    # Send work items to worker 2
    for i in 1:5
        put!(channel_1_to_2, i)
        println("Worker 1 sent work item: $i")
        sleep(0.2)
    end
    
    # Send stop signal
    put!(channel_1_to_2, :stop)
    println("Worker 1 sent stop signal")
end

# Collect results on main process
@info "Collecting results..."
round_trip_results  = []
global result_count = 0
while result_count < 5  # We expect 5 results
    try
        result = take!(result_channel)
        push!(round_trip_results, result)
        global result_count += 1
        println("Main process received: $result")
    catch e
        if isa(e, InvalidStateException)
            break
        else
            rethrow(e)
        end
    end
end

@info "Waiting for workers to complete"
wait(worker_1_task)
wait(worker_2_task)
@info ">>> DONE DONE DONE <<<"
