
wsel = wsel or {}

for k,v in pairs(wsel.PreviewIcons)do
	resource.AddFile("materials/"..v)
end
