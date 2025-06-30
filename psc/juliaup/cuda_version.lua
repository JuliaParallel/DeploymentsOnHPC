local function cuda_version()
    -- the `cuda` module might not be loaded yet (don't worry, it will be as
    -- it's a module dependency)
    local chome = os.getenv("CUDA_HOME")
    if nil == chome then return "0.0" end
    -- a bit of a hack: read the version.json to get the cuda version
    local proc  = assert(io.popen(
        "cat "..chome.."/version.json | jq -r .cuda.version | cut -d '.' -f 1-2"
    ))
    local result = proc:read("*all"):gsub("[\n,\r]", "")
    proc:close()
    return result
end



print(cuda_version())
