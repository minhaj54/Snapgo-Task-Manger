# Snapbook Setup Instructions

## Database Changes Required in Appwrite

You need to make the following changes to your Appwrite database to support the new features:

### 1. Update `tasks` Collection

Add a new attribute to your existing `tasks` collection:

- **Attribute Name:** `createdBy`
- **Type:** String
- **Size:** 255 (or appropriate size)
- **Required:** No (to support existing tasks)
- **Default:** Empty string

**Steps:**
1. Go to your Appwrite Console
2. Navigate to Databases → Your Database (ID: `68ee9a9f001a1fbc26a4`)
3. Select the `tasks` collection
4. Click "Create Attribute"
5. Add the `createdBy` string attribute as specified above

### 2. Create New `comments` Collection

Create a new collection called `comments` with the following attributes:

- **Collection Name:** `comments`
- **Collection ID:** `comments` (or let Appwrite generate one)

**Attributes:**

1. **taskId**
   - Type: String
   - Size: 255
   - Required: Yes

2. **authorName**
   - Type: String
   - Size: 255
   - Required: Yes

3. **content**
   - Type: String
   - Size: 10000 (for longer comments)
   - Required: Yes

**Note:** You don't need to create `createdAt` or `updatedAt` attributes manually. Appwrite automatically provides `$createdAt` and `$updatedAt` fields for all documents.

**Indexes (Recommended for better performance):**

1. Create an index on `taskId` to quickly fetch comments for a specific task
   - Key: `taskId`
   - Type: Key
   - Order: ASC

**Permissions:**

Set appropriate permissions for the `comments` collection. Recommended settings:
- Read: Any
- Create: Any (authenticated users)
- Update: Any (will be controlled by the app - only comment authors)
- Delete: Any (will be controlled by the app - only comment authors)

### 3. Update Permissions (Optional but Recommended)

Review and update permissions for the `tasks` collection if needed:
- Since all users can now create tasks, ensure "Create" permission is set to "Any" or appropriate role
- Read, Update, and Delete permissions should be set appropriately

## Features Implemented

### 1. Comment System
- ✅ Users can add comments to any task
- ✅ Comments display with author name and timestamp
- ✅ Real-time updates for comments
- ✅ Users can edit their own comments (shows "edited" indicator)
- ✅ Users can delete their own comments
- ✅ Comments show relative time (e.g., "2h ago", "just now")

### 2. Task Assignment Changes
- ✅ All users can now create tasks (not just admin)
- ✅ All users can assign tasks to any other user
- ✅ Task creators can edit and delete their own tasks
- ✅ Admins can still edit and delete all tasks
- ✅ Users see the "Created by" field in task details
- ✅ Floating Action Button (FAB) is now visible to all users

## Testing the Features

After setting up the database:

1. **Test Comments:**
   - Open any task detail page
   - Write a comment and post it
   - Verify it appears in the list
   - Try editing your own comment
   - Try deleting your own comment
   - Verify you cannot edit/delete other users' comments

2. **Test Task Creation:**
   - Log in as a non-admin user
   - Click the FAB button to create a new task
   - Assign it to one or more users
   - Verify the task is created with you as the creator

3. **Test Task Editing:**
   - As a task creator, swipe left on your task to edit
   - Verify you can edit your own tasks
   - Try to edit someone else's task (should not be allowed unless you're admin)

4. **Test Real-time Updates:**
   - Open the same task on two different devices/browsers
   - Post a comment on one device
   - Verify it appears on the other device in real-time

## Notes

- Existing tasks without a `createdBy` field will work but won't have edit/delete permissions for non-admin users
- You may want to manually update existing tasks to set the `createdBy` field
- The `$createdAt` and `$updatedAt` fields are automatically managed by Appwrite for all documents (tasks and comments)
- The app uses `$updatedAt` to detect when comments are edited
- Real-time subscriptions require WebSocket support in your environment

## Troubleshooting

**If comments don't appear:**
- Check that the `comments` collection was created correctly
- Verify permissions are set correctly
- Check browser console for any errors

**If you get permission errors:**
- Ensure the Appwrite permissions are set to "Any" for appropriate operations
- Check that you're logged in with a valid session

**If real-time updates don't work:**
- Verify WebSocket connections are not blocked by firewall
- Check Appwrite console for realtime connection status
- Ensure your Appwrite instance supports realtime features

## Next Steps

After completing the database setup, you can:
1. Run the app and test all features
2. Consider adding notifications for new comments
3. Add pagination for comments if tasks accumulate many comments
4. Add rich text formatting for comments
5. Add file attachments to comments

