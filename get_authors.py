import yaml

CONFIG_FILE = "users.yaml"

with open(CONFIG_FILE, "r") as f:
    data = yaml.safe_load(f)


for mod in data.get("mods", []):
    if mod.get("username") == "divya":
        authors = mod.get("authors", [])
        for author in authors:
            print(author)
        break