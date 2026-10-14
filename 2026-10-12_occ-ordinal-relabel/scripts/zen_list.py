import os,requests
tok=open(os.path.expanduser("~/.zenodo_token")).read().strip();H={"Authorization":f"Bearer {tok}"}
d=requests.get("https://zenodo.org/api/deposit/depositions/23209841",headers=H,timeout=60).json()
fs=d.get("files",[]);print("submitted",d.get("submitted"),"n",len(fs))
for x in fs: print(x["filename"],x["filesize"])
