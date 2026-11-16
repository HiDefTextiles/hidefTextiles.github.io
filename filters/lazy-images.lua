-- Load every content image lazily unless the page says otherwise.
function Image(el)
  if el.attributes.loading == nil then
    el.attributes.loading = "lazy"
  end
  return el
end
