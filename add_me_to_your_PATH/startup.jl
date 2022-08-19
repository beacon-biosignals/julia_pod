@info "Running startup.jl"

# start julia after repl history gets a chance to sync; is there a better way??
n=8
sleep(n)
@info "done waiting $n secs for logs/repl_history.jl to sync..."

# pushfirst!(LOAD_PATH, raw"/julia-vscode/scripts/packages")
# using VSCodeServer
# popfirst!(LOAD_PATH)
# VSCodeServer.serve(4242,
#                    is_dev = "DEBUG_MODE=true" in Base.ARGS,
#                    crashreporting_pipename = raw"/tmp/vsc-jl-cr-b7089624-d6ca-4a6f-8942-563942f32a32")

