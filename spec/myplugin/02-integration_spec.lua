local helpers = require "spec.helpers"


local PLUGIN_NAME = "kong-builders"


for _, strategy in helpers.all_strategies() do
  if strategy == "postgres" then
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME })

      -- Inject a test route. No need to create a service, there is a default
      -- service which will echo the request.
      local route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })
      -- add the plugin to test to the route we created
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
          config = {
            auth_url = "http://httpbin.org/status/200"
          },
        }

        local route2 = bp.routes:insert({
          hosts = { "test2.com" },
        })
        -- add the plugin to test to the route we created
        bp.plugins:insert {
          name = PLUGIN_NAME,
          route = { id = route2.id },
          config = {
            auth_url = "http://httpbin.org/status/403"
          },
        }

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
        -- write & load declarative config, only if 'strategy=off'
        declarative_config = strategy == "off" and helpers.make_yaml_file() or nil,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)



    describe("request", function()
      it("gets a 'hello-world' header", function()
        local r = client:get("/request", {
          headers = {
              ["Mini-Auth"] = "super-sec",
              ["host"] = "test1.com"
          }
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- now check the request (as echoed by the mock backend) to have the header
        local header_value = assert.request(r).has.header("hello-world")
        -- validate the value of that header
        assert.equal("this is on a request", header_value)
      end)
      end)
    end)

  end
end
