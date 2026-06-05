# §7. Accessing External Resources

**When you cannot access a resource that the user can easily access:**

- ALWAYS ask for help IMMEDIATELY
- DO NOT conclude "this is a dead end" or "resource not accessible" without asking user first
- Only mark a resource as truly inaccessible after user confirms they also cannot access it

**Examples of when to ask for user help:**

1. **Paywalled or access-restricted content**: "I can't access [URL] - it's behind a paywall. Can you copy the content for me?"
2. **404 or redirect errors**: "I got a 404/redirect trying to access [URL]. Can you help me access this or provide the content?"
3. **Private repositories**: "This repo requires authentication. Can you grant me access or share the relevant code?"
4. **Inspecting webpage elements**: "I need to see the HTML structure of [element]. Can you inspect it in your browser and save the HTML to a file for me?"
5. **Browser-rendered content**: "This page uses JavaScript rendering. Can you view the page source and share it with me?"
6. **Local files user has access to**: "Can you check if [file] exists at [path] and share its contents?"
7. **Documentation requiring login**: "This documentation requires login. Can you access it and share the relevant section?"

**How to ask effectively:**
- Be specific about what you need
- Suggest exactly how user can help (e.g., "Can you save the HTML to `/archive/temp_element.html`?")
- Explain why you need it (e.g., "I need to see the button attributes to fix the state issue")
- User may have browser DevTools, file system access, or authentication that tools lack
