-- YouTube embeds wait for cookie consent (consent/consent.js, Klaro!):
-- <iframe src="https://www.youtube-nocookie.com/..."> becomes
-- <iframe data-name="youtube" data-src="..."> and Klaro shows a
-- "load video" notice in its place until YouTube is allowed.
local function gate(text)
  return (text:gsub('<iframe([^>]-) src="(https://www%.youtube%-nocookie%.com/[^"]*)"',
    '<iframe%1 data-name="youtube" data-src="%2"'))
end

function RawBlock(el)
  if el.format == "html" then el.text = gate(el.text) end
  return el
end

function RawInline(el)
  if el.format == "html" then el.text = gate(el.text) end
  return el
end
