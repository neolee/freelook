local choices = {
  { id = "github-dark", title = "GitHub Dark", is_dark = true },
  { id = "github-light", title = "GitHub Light", is_dark = false },
}

local function select_default(list, prefers_dark)
  for _, choice in ipairs(list) do
    if choice.is_dark == prefers_dark then
      return choice
    end
  end

  return list[1]
end

return select_default(choices, true)
