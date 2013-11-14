
conf = {
  {
    bla = "blbli"
  },
  {
    bla = "fasel"
  },
  {
    bla = "hoppla"
  }
}

for k, v in pairs(conf) do
  print("XXX", k, v, conf[k].bla)
end

