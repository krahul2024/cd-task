#! usr/bin/bash

releaseId=$1
assignee=$2
parentFeature=$3
itracAuth=$4

if [ -z $itracAuth ]; then
    echo "invalid token"
fi


projectKey=$(jq -r '.projectConfig.projectKey' meta.json)
parentIssueType=$(jq -r '.projectConfig.issueType.parent' meta.json)
subtaskIssueType=$(jq -r '.projectConfig.issueType.subtask' meta.json)
components=$(jq -c '.projectConfig.components' meta.json)
createIssueUrl="https://itrac.eur.ad.sag/rest/api/latest/issue"
linkUrl="https://itrac.eur.ad.sag/rest/api/latest/issueLink"
issueTypeUrl="https://itrac.eur.ad.sag/rest/api/latest/issueLinkType"

#-----------------------------------parent issue

curl -v \
-H "Content-Type: application/json"  \
-H "Authorization: Bearer $itracAuth" \
--data '
        {
            "fields" : {
                "project" : {
                    "key" : "'"$projectKey"'"
                },
                "assignee" : {
                    "name" : "'"$assignee"'"
                },
                "summary" : '"$(jq --arg releaseId "$releaseId" '.parentTask.summary | gsub("\\$releaseId"; $releaseId)' meta.json)"',
                "description" : '"$(jq --arg releaseId "$releaseId" '.parentTask.description | gsub("\\$releaseId"; $releaseId)' meta.json)"',
                "issuetype" : {
                    "name" : "'"$parentIssueType"'"
                },
                "components" : '"$components"'
            }
        }
' \
-o response.json \
"$createIssueUrl"

cat response.json | jq


#---------------------------------sub-task issues
parentKey=$(jq -r '.key' response.json)
printf "Creating Sub-Task issues for parent issue :  $parentKey\n"


for ((i=0; i<1; i++)); do
    description=$(jq -r '.subtasks['$i'].description' meta.json)
    curl -v \
    -H "Content-Type: application/json"  \
    -H "Authorization: Bearer $itracAuth" \
    --data '
        {
            "fields" : {
                "project" : {
                    "key" : "'"$projectKey"'"
                },
                "parent" : {
                    "key" : "'"$parentKey"'"
                },
                "assignee" : {
                    "name" : "'"$assignee"'"
                },
                "summary" : '"$(jq --arg releaseId "$releaseId" '.subtasks['$i'].summary | gsub("\\$releaseId"; $releaseId)' meta.json)"',
                "description" : '"$(jq --arg releaseId "$releaseId" '.subtasks['$i'].description | gsub("\\$releaseId"; $releaseId)' meta.json)"',
                "issuetype" : {
                    "name" : "'"$subtaskIssueType"'"
                },
                "components" : '"$components"'
            }
        }
    ' \
    "https://itrac.eur.ad.sag/rest/api/latest/issue"
done



#----------------------Linking the issues
printf "Linking the issues...."

curl -v \
-H "Content-Type: application/json"  \
-H "Authorization: Bearer $itracAuth" \
--data '{
	    "type": {
	        "name": "Feature Hierarchy"
	    },
	    "inwardIssue": {
	        "key": "'$parentKey'"
	    },
	    "outwardIssue": {
	        "key": "'$parentFeature'"
	    },
	    "comment": {
	        "body": "Linked related issue!"
	    }
}' \
-o link_response.json \
"$linkUrl"



