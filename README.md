# Vakil Sirji Property Manager

A comprehensive, real-time property management and agreement generation dashboard built with **Flutter Web** and **Supabase**.

## 🚀 Features

* **Multi-Role Authentication**: Secure login and role-based access for Admins, Owners, and Tenants.
* **Comprehensive Agreement Wizard**: A powerful multi-step stepper form for admins to draft lease agreements. Captures dynamic property data, calculates lease periods, and securely stores full profiles (PAN, Aadhaar, Addresses) for Owners, Tenants, and multiple Witnesses.
* **Real-time Dashboards**: Built with Riverpod and Supabase streams, the UI reacts instantly to database changes—no manual refreshing required.
* **Draft Management**: Save complex agreement data seamlessly into flexible JSON structures for easy retrieval, modifications, and future government registration.
* **Property & Customer Directories**: Manage rental properties, track statuses (Vacant/Active), and manage customer (owner/tenant) profiles.

## 🛠 Tech Stack

* **Frontend**: [Flutter Web](https://flutter.dev/)
* **State Management**: [Riverpod](https://riverpod.dev/)
* **Backend as a Service**: [Supabase](https://supabase.com/)
  * PostgreSQL Database
  * Real-time Subscriptions
  * Row Level Security (RLS)
* **Routing**: [GoRouter](https://pub.dev/packages/go_router)

## 📦 Getting Started

### Prerequisites
* Flutter SDK (Latest stable version)
* Supabase Account & Project

### Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git
   ```
2. Navigate to the project directory:
   ```bash
   cd vs_property_manager
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Set up your Supabase environment variables in a `.env` file:
   ```env
   SUPABASE_URL=your_project_url
   SUPABASE_ANON_KEY=your_anon_key
   ```
5. Run the SQL scripts found in the root directory (e.g., `database_schema.sql`, `alter_schema.sql`, `alter_agreements.sql`) in your Supabase SQL Editor.
6. Run the app:
   ```bash
   flutter run -d chrome
   ```
