local env = getfenv()
env['...'] = {["#"]=select("#", ...), ...}
sh.browse(env, "env")
