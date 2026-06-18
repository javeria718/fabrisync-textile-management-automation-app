
# FabriSync

FabriSync is a **Department-Driven Textile Production & Cost Management System** developed as a **Final Year Project (FYP)** for the textile industry. It supports order creation, dynamic cost estimation, production workflow tracking, and role-based access control across **Admin**, **Manager**, and **Employee Head** roles.

![Flutter](https://img.shields.io/badge/Flutter-3.10-02569B?logo=flutter\&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.10-0175C2?logo=dart\&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase\&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Android-success)
![License](https://img.shields.io/badge/License-Academic-blue)

[![Live Demo](https://img.shields.io/badge/Live-Web%20App-00C7B7?logo=netlify\&logoColor=white)](https://fabrisync-final.netlify.app/)
[![Watch Demo](https://img.shields.io/badge/Watch-Demo%20Video-FF0000?logo=youtube\&logoColor=white)](https://drive.google.com/file/d/1WAuscHS5-hyeXgwiY8BbGcsK6eMDnqoJ/view?usp=sharing)

The application combines a **Flutter frontend** with a **Supabase backend** to deliver a production-oriented workflow for **Curtains, Abayas, and Bedsheets**. Its primary objective is to help textile operations transition from manual costing and tracking processes to a data-driven manufacturing workflow with accurate estimates, automated department schedules, and real-time status visibility.

### Key Benefits

* Structured order creation with dynamic cost estimation
* Role-specific dashboards for Admins, Managers, and Employee Heads
* Automated department sequencing and item-level progress tracking
* Supabase-backed persistence with secure access control and cost configuration tables

---

## Features

### Authentication

* Supabase-based user authentication
* Role selection for Admin, Manager, and Employee Head
* Role-guarded dashboard access
* Password recovery through Supabase reset flow

### Order Management

* Order creation for Curtains, Abayas, and Bedsheets
* Draft order saving and expiry handling
* Automated order ID generation
* Order details stored in `ordersmain`

### Cost Estimation

* Product-specific cost engines for:

  * Curtains
  * Abayas
  * Bedsheets
* Material, labor, processing, and additional charge calculations
* Wastage and quality multipliers
* Rush delivery detection and surcharge calculation
* Cost breakdown persistence in `order_cost_breakdown`

### Workflow Management

* Department workflow sequencing via `department_orders`
* Automatic department assignment after order creation
* Automatic next-department transition on completion
* Item-level tracking using:

  * `order_items`
  * `item_department_progress`
  * `item_progress_logs`
* Delay reason capture for overdue tasks

### Dashboard & Analytics

* KPI summaries for administrators
* Department progress overview
* Real-time updates using Supabase Realtime
* Interactive order tables powered by `data_table_2`

### Notifications

* Deadline alerts for delayed orders
* Real-time status refresh mechanisms

---

## User Roles

| Role              | Responsibilities                                                                  |
| ----------------- | --------------------------------------------------------------------------------- |
| **Admin**         | Full system access, manage orders, monitor analytics, and configure cost settings |
| **Manager**       | Oversee department workflows, review active orders, and monitor progress          |
| **Employee Head** | Update item completion status and manage department-level tasks                   |

---
---

## Use Case Diagrams

### Admin Use Case Diagram

<p align="center">
  <img src="assets/diagrams/admin-usecase.png" width="900" alt="Admin Use Case Diagram">
</p>

The Admin manages users, creates orders, monitors production workflows, configures costing parameters, tracks department progress, and views analytics dashboards.

---

### Manager Use Case Diagram

<p align="center">
  <img src="assets/diagrams/manager-use-case.png" width="900" alt="Manager Use Case Diagram">
</p>

The Manager supervises department workflows, reviews assigned orders, monitors production progress, and tracks departmental performance.

---

### Employee Head Use Case Diagram

<p align="center">
  <img src="assets/diagrams/Employee-Head-usecase.drawio.png" width="900" alt="Employee Head Use Case Diagram">
</p>

The Employee Head updates item-level progress, marks tasks as completed, records delay reasons, and manages department-specific production activities.

---

## System Architecture Diagram

<p align="center">
  <img src="assets/diagrams/system-diagram.png" width="900" alt="System Architecture Diagram">
</p>

The system architecture illustrates the interaction between the Flutter frontend, Supabase backend, authentication layer, business services, and database components.

---

## Class Diagram

<p align="center">
  <img src="assets/diagrams/CLASS.drawio.png" width="900" alt="Class Diagram">
</p>

The class diagram presents the relationships between controllers, services, models, and core entities using associations, compositions, and inheritance.

---

## Entity Relationship Diagram (ERD)

<p align="center">
  <img src="assets/diagrams/erd-diagram.png" width="900" alt="Entity Relationship Diagram">
</p>

The ERD represents the database schema, including orders, users, workflows, departments, and cost configuration tables.
## Sequence Diagrams

Sequence diagrams illustrate the interaction flow between system actors, controllers, services, and the database during key operations.

### Admin Sequence Diagram

<p align="center">
  <img src="assets/diagrams/admin-sequence.png" width="900" alt="Admin Sequence Diagram">
</p>

The Admin sequence diagram demonstrates the process of authentication, order creation, cost estimation, workflow initialization, and dashboard monitoring.

---

### Manager Sequence Diagram

<p align="center">
  <img src="assets/diagrams/manager-sequence.png" width="900" alt="Manager Sequence Diagram">
</p>

The Manager sequence diagram illustrates how managers retrieve department-specific orders, monitor workflow progress, and update production statuses.

---

### Employee Head Sequence Diagram

<p align="center">
  <img src="assets/diagrams/employee-sequence.png" width="900" alt="Employee Head Sequence Diagram">
</p>

The Employee Head sequence diagram represents item-level progress updates, task completion workflows, delay remark submission, and department completion handling.

---

## Activity Diagrams

Activity diagrams describe the step-by-step workflows performed by each system role.

### Admin Activity Diagram

<p align="center">
  <img src="assets/diagrams/AdminActivity.png" width="500" alt="Admin Activity Diagram">
</p>

The Admin activity diagram outlines the process of logging in, creating orders, configuring cost parameters, monitoring production workflows, and reviewing analytics.

---

### Manager Activity Diagram

<p align="center">
  <img src="assets/diagrams/ManagerActivity.png" width="300" alt="Manager Activity Diagram">
</p>

The Manager activity diagram illustrates how department managers review assigned orders, monitor progress, and coordinate workflow execution.

---

### Employee Head Activity Diagram

<p align="center">
  <img src="assets/diagrams/EmployeeActivity.png" width="500" alt="Employee Head Activity Diagram">
</p>

The Employee Head activity diagram shows the workflow for updating item statuses, recording delays, completing department tasks, and progressing orders to the next department.

## System Architecture

* **Flutter** powers the user interface, routing, and state management.
* **Supabase** handles authentication, database operations, and real-time updates.
* `main.dart` initializes Supabase using build-time environment variables.
* Role-based access control is enforced through `RoleGuard`.
* Order estimation is centralized in `order_calculation_service.dart` and delegated to category-specific services.

### Cost Calculation Services

* `lib/services/curtain/curtain_calculation_service.dart`
* `lib/services/abaya/abaya_calculation_service.dart`
* `lib/services/bedsheet/bedsheet_calculation_service.dart`

---

## Technology Stack

| Category             | Technology         | Version            |
| -------------------- | ------------------ | ------------------ |
| Frontend             | Flutter            | Dart SDK `^3.10.1` |
| State Management     | Provider           | `^6.1.5+1`         |
| Backend              | Supabase           | `^2.12.0`          |
| Data Tables          | data_table_2       | `^2.7.2`           |
| Charts               | fl_chart           | `^1.1.1`           |
| Deep Links           | app_links          | `^6.4.1`           |
| Local Storage        | shared_preferences | `^2.5.4`           |
| Internationalization | intl               | `^0.20.2`          |
| Timeline UI          | timeline_tile      | `^2.0.0`           |
| Icons                | cupertino_icons    | `^1.0.8`           |

---

## Project Structure

```text
lib/
├── auth/
├── controllers/
├── Model/
├── onboarding/
├── services/
│   ├── abaya/
│   ├── bedsheet/
│   ├── curtain/
│   ├── draft/
│   └── ...
├── singleton/
├── utils/
├── view/
│   ├── dashboards/
│   └── newOrder/
└── widgets/

supabase/
├── migrations/
└── schema_current.sql

pubspec.yaml
lib/main.dart
README.md
```

### Folder Description

* `auth/` — Authentication screens and login flow
* `controllers/` — Business controllers for workflows and dashboards
* `Model/` — Domain models and data classes
* `onboarding/` — Splash screen and role selection flow
* `services/` — Backend integration and calculation logic
* `view/` — UI screens and dashboards
* `widgets/` — Reusable UI components
* `supabase/` — Database schema and migration scripts

---

## Database Design

| Table / View               | Purpose                                                 |
| -------------------------- | ------------------------------------------------------- |
| `profiles`                 | Stores user profiles, roles, and department assignments |
| `ordersmain`               | Core order information and production metadata          |
| `department_orders`        | Department workflow records                             |
| `order_cost_breakdown`     | Detailed cost calculations per order                    |
| `order_items`              | Individual items generated from order quantity          |
| `item_department_progress` | Item-level progress tracking                            |
| `item_progress_logs`       | Progress change history                                 |
| `v_department_orders_full` | Workflow reporting view                                 |
| `curtain_cost_config`      | Curtain pricing configuration                           |
| `abaya_cost_config`        | Abaya pricing configuration                             |
| `bedsheet_cost_config`     | Bedsheet pricing configuration                          |
| `department_sequence`      | Department transition order                             |
| `master_cost_config`       | Global cost constants                                   |
| `master_time_config`       | Department time estimates                               |

---

## Cost Estimation Engine

### Curtains

* Material cost based on fabric area and wastage
* Labor cost using header style, quality, and quantity multipliers
* Processing, packaging, and transport charges
* Rush delivery surcharge support

### Abayas

* Material cost based on size and fabric consumption
* Labor cost using complexity, quality, and fabric difficulty factors
* Premium finishing and embellishment charges
* Quantity and rush surcharges

### Bedsheets

* Material cost based on bed size and fabric type
* Labor cost including stitching, finishing, and printing
* Quality control and packaging costs
* Premium handling and rush charges

---

## Installation

### Prerequisites

* Flutter SDK compatible with Dart `^3.10.1`
* Git
* Supabase project credentials

### Clone Repository

```bash
git clone <repository-url>
cd FabriSync/fabri_sync
```

### Install Dependencies

```bash
flutter pub get
```

---

## Environment Variables

This project uses **build-time environment variables (dart-define)**.

They are NOT stored in a .env file for web builds.

### Build for Web

```bash
flutter build web --release --dart-define=SUPABASE_URL=your_supabase_url --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Build for Android

```bash
flutter build apk --release
```

---

## Running the Project

### Run on Web

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=your_supabase_url --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Run on Android

```bash
flutter run
```

---

## Deployment

### Netlify (Flutter Web)

1. Build the application using `flutter build web`.
2. Upload the contents of the `build/web` folder.
3. Configure SPA redirect rules.
4. 1. Run build command locally:

```bash
flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

### Android APK

```bash
flutter build apk --release
```

Sign and distribute the APK using standard Android tooling.

---

## Screenshots

### Authentication & Onboarding

![Splash Screen](assets/app-screenshots/splash-screen.jpeg)
![Welcome Screen](assets/app-screenshots/welcome-screen.jpeg)
![Role Selection](assets/app-screenshots/role-selection.jpeg)
![Login Screen Admin](assets/app-screenshots/login-screen-admin.jpeg)
![Manager Login](assets/app-screenshots/manager-login.png)
![Employee Head Login](assets/app-screenshots/employee-head-login.png)

### Order Creation Workflow

![Order Creation Step 1](assets/app-screenshots/order-creation-step1.png)
![Order Creation Step 2](assets/app-screenshots/order-creation-step2.png)
![Order Creation Step 3](assets/app-screenshots/order-creation-step3.png)
![Order Creation Step 4](assets/app-screenshots/order-creation-step4.png)
![Order Creation Step 5](assets/app-screenshots/order-creation-step5.png)
![Order Creation Step 5.1](assets/app-screenshots/order-creation-step5.1.png)
![Order Dialog Box](assets/app-screenshots/order-dialog-box.png)

### Product Configuration Guides

![Order Creation Guide Curtain](assets/app-screenshots/order-creation-guide-curtain.png)
![Order Creation Guide Abaya](assets/app-screenshots/order-creation-guide-abaya.png)
![Order Creation Guide Bedsheet](assets/app-screenshots/order-creation-guide-bedsheet.png)

### Cost Estimation & Order Details

![Order Details](assets/app-screenshots/order-details.jpeg)
![Order Details 1](assets/app-screenshots/order-details-1.png)
![All Orders Estimated Time](assets/app-screenshots/all-orders-estimated-time.png)

### Admin Dashboard

![Admin Dashboard](assets/app-screenshots/admin-dashboard.jpeg)
![Admin Table](assets/app-screenshots/admin-table.jpeg)
![Draft Orders](assets/app-screenshots/draft-orders.jpeg)

### Manager Dashboards

![Manager Panel Cutting](assets/app-screenshots/manager-panel-cutting.jpeg)
![Manager Panel Inspection](assets/app-screenshots/manager-panel-inspection.png)
![Manager Panel Stitching](assets/app-screenshots/manager-panel-stitching.png)
![Manager Panel Threading](assets/app-screenshots/maanger-panel-threading.png)
![Manager Panel Packaging](assets/app-screenshots/maanger-panel-packaging.png)
![Manager Panel Quality Control](assets/app-screenshots/maanger-panel-quality-control.png)
![Manager Table View](assets/app-screenshots/manager-table-view.png)

### Employee Head Dashboard

![Employee Head Panel Cutting](assets/app-screenshots/employee-head-panel-cutting.png)
![Employee Head Panel Stitching](assets/app-screenshots/employee-head-panel-stitching.png)
![Employee Head Panel Threading](assets/app-screenshots/employee-head-panel-threading.png)
![Employee Head Panel Quality Control](assets/app-screenshots/employee-head-panel-quality-control.png)
![Employee Head Panel Packaging](assets/app-screenshots/employee-head-panel-packaging.png)
![Employee Head Panel Inspection](assets/app-screenshots/employee-head-panel-inspection.png)

## Future Enhancements

* Customer Order Portal
* ERP Integration

---

## Contributors

* **Javeria Shahid**

---

## License

This project was developed for academic purposes as a **Final Year Project (FYP)**.
