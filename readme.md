# 🧠 Task Management App (Flutter + Appwrite)

A **Flutter + Appwrite** powered task management app with **role-based access** — Admins can assign tasks, and Users can view tasks assigned to them.

---

## 🚀 Features

- 🔐 **Login / Register Page** with fields:
    - Name
    - Email
    - Password
- 👋 **Welcome Screen** with intro text and smooth UI
- 🏠 **Home Page / Tasks Page**
    - **Admin View:** Shows all tasks + Floating Action Button to add tasks
    - **User View:** Shows only tasks assigned to the logged-in user
- 📝 **Add Task Page**
    - Text fields for: Title, Description
    - Dropdown to select user (from Appwrite user list)
    - Date picker for Deadline
    - Dropdown for Status (Pending, In Progress, Completed)
- 🔄 **Real-time sync** using Appwrite Database
- 🧩 **Role-based Navigation** (Admin vs User)
- 💾 **Appwrite Authentication & Database Integration**

---


### 2️⃣ Appwrite Setup

#### 🧩 Create Project
1. Go to Appwrite Console → Create a new project.
2. Add a platform → Flutter Web/Android/iOS → get the Project ID and Endpoint.

#### 🔐 Create Collections

##### 🧱 Collection: `tasks`
| Field Name | Type       | Description               |
|-------------|------------|---------------------------|
| title       | String     | Task title                |
| description | String     | Task details              |
| assignedTo  | String     | User ID of assignee       |
| deadline    | DateTime   | Task deadline             |
| status      | Enum       | pending / in-progress / completed |
| createdBy   | String     | Admin user ID             |

---

## 📂 Folder Structure

│
├── main.dart
├── appwrite/
│ ├── appwrite_client.dart
│ ├── auth_service.dart
│ └── database_service.dart
│
├── screens/
│ ├── login_page.dart
│ ├── home_page.dart
│ ├── add_task_page.dart
│
├── models/
│ └── task_model.dart
│
└── widgets/
└── task_card.dart


---

## ⚙️ Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  appwrite: ^11.0.1
  fluttertoast: ^8.2.4
  google_fonts: ^6.1.0
  intl: ^0.19.0
```

🧠 App Logic Overview
🔹 Login / Register Page

Users enter Name, Email, Password.

On register:
Create user via Appwrite account.create()
Store role (admin/user) in Appwrite database (optional)

On login:
Authenticate via account.createEmailSession()
Redirect to Home Page

🔹 Home Page (Tasks Page)
If Logged-in User is Admin
Fetch all tasks from Appwrite tasks collection.
Show in a list with task cards.
Floating Action Button ➜ Opens AddTaskPage.
If Logged-in User is User
Fetch only tasks where assignedTo == userId.
Display those tasks.

🔹 Add Task Page (Admin Only)
Input fields:
Title
Description
Dropdown to select a user (fetch all users via databases.listDocuments() from user collection)
DatePicker for deadline
Status dropdown (pending, in-progress, completed)
On “Add Task”, create a document in tasks collection.# Snapgo-Task-Manger
# Snapgo-Task-Manger
![snapgo app screenshot .png](../snapgo%20app%20screenshot%20.png)