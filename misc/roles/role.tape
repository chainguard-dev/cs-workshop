Output roles.mp4
Require echo 

Set Shell 'zsh'
Set Width 2000
Set Height 1800
Set TypingSpeed 70ms

Set Shell zsh
Sleep 2.5s
Type "Lets talk about chainguard roles" Sleep 500ms
Ctrl+C
Sleep 2s
Type "To list all roles, run chainctl iam roles list" Sleep 1s 
Ctrl+C
Sleep 500ms
Type "chainctl iam roles list" Sleep 500ms
Enter
Sleep 3s
Type "To list your orgs roles, run chainctl iam roles list --parent <yourorg>" Sleep 1s
Ctrl+C
Sleep 1s
Type "chainctl iam roles list --parent badlyenginee.red" Sleep 500ms
Enter
Sleep 5s
Type "You can also output to JSON with --output json" Sleep 1s
Ctrl+C
Sleep 2s
Type "chainctl iam roles list --parent badlyenginee.red --output json" Sleep 1s
Enter
Sleep 6s
Type "To list capabilities (claims) run chainctl iam roles capabilities list" Sleep 1s
Ctrl+C
Type "chainctl iam roles capabilities list"
Sleep 500ms
Enter
Sleep 5s
Type "Lets create a new role with chainctl iam roles create" Sleep 500ms
Ctrl+C
Type "chainctl iam roles create mytest --parent badlyenginee.red --capabilities apk.list,repo.list -y" Sleep 500ms
Enter
Sleep 5s
Type "chainctl iam roles list --parent badlyenginee.red" Sleep 500ms
Enter
Sleep 3s
Type "To delete the role, you must pass the role ID" Sleep 500ms
Ctrl+C
Type `chainctl iam roles delete $(chainctl iam roles list --parent badlyenginee.red --output json | jq -r '.items[] | select(.name == "mytest").id') -y` Sleep 500ms
Enter
Sleep 5s
Type `Let's create a role for pull tokens` Sleep 500ms
Ctrl+C
Type `chainctl iam roles create pull-token-role --parent badlyenginee.red --capabilities apk.list,groups.list,identity.create,manifest.list,manifest.metadata.list,record_signatures.list,repo.list,role_bindings.create,roles.list,sboms.list,tag.list,vuln_reports.list,identity.list,identity.delete -y` Sleep 500ms
Enter
Sleep 5s
Type `Now let's create an identity for a GitHub repo with our newly defined role` Sleep 500ms
Ctrl+C
Type `chainctl iam identities create github myrepo-identity --github-repo=myorg/myrepo --parent=badlyenginee.red --role pull-token-role -y` Sleep 500ms
Enter
Sleep 5s
Type `Now in your pipeline, you can easily call chainguard Auth with the "setup-chainctl" action in your workflow and pass your new identity` Sleep 500ms
Ctrl+C
Type `Then in a second step you can create the pull token by running` Sleep 500ms
Ctrl+C
Type `chainctl auth pull-token --ttl 1h --name my-pull-token` Sleep 500ms
Ctrl+C
Sleep 2s
Type `Before you delete a role, you need to delete the associated identity` Sleep 500ms
Ctrl+C
Sleep 2s
Type `To delete an identity, you need to pass the ID` Sleep 500ms
Ctrl+C
Sleep 2s
Type `chainctl iam identities delete $(chainctl iam identities list --output json --parent badlyenginee.red | jq -r '.items[] | select(.name == "myrepo-identity").id') -y` Sleep 500ms
Enter
Sleep 5s
Type `To delete the role, you need to pass the ID` Sleep 500ms
Ctrl+C
Sleep 2s
Type `chainctl iam roles delete $(chainctl iam roles list --output json --parent badlyenginee.red | jq -r '.items[] | select(.name == "pull-token-role").id') -y` Sleep 500ms
Enter
Sleep 3s
Type `Thank you!` Sleep 500ms
Ctrl+C
Sleep 5s
