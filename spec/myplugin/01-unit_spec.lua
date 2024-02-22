local PLUGIN_NAME = "kong-builders"


-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end


describe(PLUGIN_NAME .. ": (schema)", function()


  it("auth_header is required", function()
    local ok, err = validate({
      auth_header = ngx.null,
    })
    assert.is_falsy(ok)
    assert.is_table(err)
    assert.equals('required field missing', err.config.auth_header)
  end)
end)
