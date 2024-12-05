
import re
import requests

# Obviously you should not hardcode your API key in the code,
# BUT in this case setting up the env variable would be overkill,
# and we push quite a lof of other keys as well, + it's a private repo, + it's "just" the Linear key (from @Chris).
api_key = "lin_api_AIIakeMIcFOaIX1uuQ4fJBsGL7rT5gHVUI9QnxmT"

def get_title_from_linear(branch_name: str) -> str:
    """
    Takes a string like "dev-1234", validates the format, converts it to "DEV-1234",
    and retrieves the issue title and labels from the Linear API. Formats the output
    with an emoji based on labels.

    Args:
        branch_name (str): The branch name in the format "dev-{anyNumber}".
        api_key (str): Linear API key for authentication.

    Returns:
        str: The formatted title with emoji, looking like "🐛 dev-1234: Issue Title".
        None: An error occurred.
    """
    error_prefix = "Error getting Title from Linear Ticket: "

    # Validate the format
    if not re.match(r'^dev-\d+$', branch_name):
        print(f"{error_prefix}Invalid format. The branch name must be in the format 'dev-{anyNumber}'.")
        return None

    # Convert to issue ID format
    issue_id = branch_name.upper()  # Convert "dev-1234" to "DEV-1234"

    # Define the GraphQL query
    query = f"""
    query {{
        issue(id: "{issue_id}") {{
            title
            labels {{
                nodes {{
                    name
                }}
            }}
        }}
    }}
    """

    # Send the request
    url = "https://api.linear.app/graphql"
    headers = {
        "Content-Type": "application/json",
        "Authorization": api_key
    }
    payload = {"query": query}

    try:
        response = requests.post(url, json=payload, headers=headers)
        response.raise_for_status()  # Raise exception for HTTP errors
        data = response.json()

        # For debugging
        # print(f"Response JSON: {data}")

        # Check for errors in the response
        if "errors" in data:
            print(f"{error_prefix}{data['errors']}")
            return None

        # Extract issue details
        issue = data.get("data", {}).get("issue")
        if not issue:
            print(f"{error_prefix}Issue not found.")
            return None

        # Get the title and labels
        issue_title = issue.get("title")
        labels = [label["name"] for label in issue.get("labels", {}).get("nodes", [])]

        # Determine the emoji
        emoji = "🐛" if "Bug" in labels else "✨"

        # Format the final title
        full_title = f"{emoji} {branch_name}: {issue_title}"
        return full_title
    except requests.exceptions.RequestException as e:
        print(f"{error_prefix}{e}")
        return None
