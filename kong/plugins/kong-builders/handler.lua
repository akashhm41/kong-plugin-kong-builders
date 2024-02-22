local http = require("resty.http")

local plugin = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1", -- version in X.Y.Z format. Check hybrid-mode compatibility requirements.
}

local function makeApiCall(auth_id)
  -- Single-shot requests use the `request_uri` interface.
  local httpc = http.new()
  local res, err = httpc:request_uri(
    string.format("https://jsonplaceholder.typicode.com/todos/%s", "1"),
    {
      method = "GET",
      -- body = "token=" .. auth_header,
      -- headers = {
      --   ["Content-Type"] = "application/text",
      -- },
    })
  if not res then
    ngx.log(ngx.ERR, "request failed: ", err)
    return kong.response.exit(500, "Custom internal server error")
  end

  -- kong.service.request.set_header(plugin_conf.request_header, "this is on a request")
  kong.log.inspect('response from api', res.body)
  return res.body
end

-- runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)
  kong.log.inspect('access plugin invoked', plugin_conf)

  -- your custom code here
  local auth_header = kong.request.get_header(plugin_conf.auth_header)
  if not auth_header then
    return kong.response.exit(403, "Not authenticated")
  end

  -- cache check
  local function cb()
    local cache_value = makeApiCall(plugin_conf.auth_id)
    return cache_value
  end

  local value, err = kong.cache:get('x-cache-key', nil, cb)
  kong.log.inspect('cache value ', value)
end --]]

-- return our plugin object
return plugin
