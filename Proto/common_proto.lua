local common_types = [[
.Skill {
    id 0 : integer
    level 1 : integer
}
.Base {
  hp 0 : integer
  level 1 : integer
  skillList 2 : *Skill
}

]]

return common_types