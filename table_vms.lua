local file=io.open("runningvms.list","r")
local line=file:read("*l")
local a={}

while line~=nil do
	a[line]=file:read("*l")
	line=file:read("*l")
end

--print the lines
for i,vm in pairs(a) do
	print(vm)
end

