git init
git add -A
git commit -m "Create a new repo"
curl -H "Content-Type: application/json" -u $USERNAME -X POST -d "{\"name\":\"$repo\", \"description\":\" A Repo is created"}" https://\
github.com/api/v3/orgs/$org/repos
git remote add origin https://$USERNAME@github.com/$org/$repo.git
git push origin master
