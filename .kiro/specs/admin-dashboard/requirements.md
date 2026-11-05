# Requirements Document

## Introduction

This feature adds the **Admin Dashboard** to the existing Sanlo tailoring Flutter app. Sign-in/sign-up is already in place; a list of admin phone numbers is stored in Firebase Realtime Database, and a user who signs in with an admin number is routed to the admin experience instead of the customer bottom-nav shell.

This spec covers the **UI only**. Every admin screen renders from in-memory mock data exposed through repository interfaces (mirroring the existing customer-side architecture), so the data layer can later be swapped for Firebase without touching presentation or domain code. No create/update actions persist yet — status changes, product add/edit, and search operate on in-memory state so the screens are visually complete and interactive.

The admin area comprises four destinations plus one sub-screen, each with a responsive layout:

- **Admin Dashboard** – date + time-of-day greeting, four summary cards, "Orders by stage" cards, and a "Recent orders" table.
- **Admin Orders** – stage filter chips, an order list, and an order-detail panel with a status stepper.
- **Admin Products** – searchable product table with per-row Edit and a top-level Add product action.
- **Admin Add/Edit Product** – a form screen opened from the Add product / Edit actions.
- **Admin Customers** – searchable customer table.

On wide screens the admin uses a persistent left sidebar; on narrow (mobile) screens it uses a bottom navigation bar with a condensed dashboard, matching the supplied designs.

## Glossary

- **Admin_App**: The admin-facing portion of the Sanlo Flutter application under specification.
- **Admin_Gate**: The routing decision that sends a user whose signed-in mobile number is in the admin allow-list to the Admin_App rather than the customer shell.
- **Admin_Shell**: The responsive navigation container hosting the four admin destinations (sidebar on wide screens, bottom nav on narrow screens).
- **Admin_Dashboard_System**: The component that loads dashboard summary metrics, stage counts, and recent orders (backed by a cubit and an admin repository).
- **Admin_Orders_System**: The component that lists admin orders, filters them by stage, and advances an order's stage (backed by a cubit and an admin repository).
- **Admin_Products_System**: The component that lists, searches, adds, and edits products (backed by a cubit and an admin repository).
- **Admin_Customers_System**: The component that lists and searches customers (backed by a cubit and an admin repository).
- **Admin_Data_Layer**: The admin repository interface and its in-memory mock implementation plus the seeded mock data source.
- **Order_Stage**: The admin order lifecycle value, one of: Ordered, Measurement done, Stitching started, Stitching finished, Final touch-up, All set.
- **Stage_Filter**: The selectable chip set on Admin Orders with values All plus each Order_Stage, each showing a count.
- **Greeting**: The time-of-day salutation shown on the dashboard — "Good morning", "Good afternoon", "Good evening", or "Good night".
- **Measurement_State**: Whether a customer entered measurements online ("Entered") or chose to measure at the shop ("Not sure").
- **Customer_Type**: Whether a customer is a "Guest" or "Registered" user.
- **Product_Visibility**: Whether a product is shown to customers ("Live") or hidden ("Hidden").
- **Wide_Layout**: The layout used when the available width is at or above the responsive breakpoint (sidebar navigation).
- **Narrow_Layout**: The layout used when the available width is below the responsive breakpoint (bottom-nav navigation).

## Requirements

### Requirement 1: Admin routing and shell

**User Story:** As a shop owner whose number is on the admin list, I want to land in an admin workspace after signing in, so that I can manage the shop instead of seeing the customer catalog.

#### Acceptance Criteria

1. WHEN an authenticated user's mobile number is present in the admin allow-list, THE Admin_Gate SHALL route the user to the Admin_App entry (Admin Dashboard) instead of the customer shell.
2. WHEN an authenticated user's mobile number is not in the admin allow-list, THE Admin_Gate SHALL route the user to the customer shell as before.
3. WHILE the available width is at or above the responsive breakpoint, THE Admin_Shell SHALL present a persistent left sidebar with the brand mark, an "ADMIN" badge, destinations (Dashboard, Orders, Products, Customers), and a "Sign out" action.
4. WHILE the available width is below the responsive breakpoint, THE Admin_Shell SHALL present a bottom navigation bar with the four destinations (Dashboard, Orders, Products, Customers).
5. WHEN a user selects a destination in the Admin_Shell, THE Admin_Shell SHALL display that destination's screen and indicate it as the active destination.
6. WHERE the Orders destination has new orders, THE Admin_Shell SHALL display a "new" count badge on the Orders destination label.
7. WHEN a user selects "Sign out", THE Admin_App SHALL reset authentication and navigate to the Sign in screen.

### Requirement 2: Dashboard overview

**User Story:** As an admin, I want a dashboard that greets me and summarizes the shop's workload, so that I can see the day's status at a glance.

#### Acceptance Criteria

1. WHEN the Admin Dashboard loads, THE Admin_Dashboard_System SHALL display the current date formatted as weekday and day-month (e.g. "Sunday, 25 October").
2. WHEN the Admin Dashboard loads, THE Admin_Dashboard_System SHALL display a Greeting chosen from the current local time: "Good morning" for 05:00–11:59, "Good afternoon" for 12:00–16:59, "Good evening" for 17:00–20:59, and "Good night" otherwise.
3. WHEN the Admin Dashboard loads, THE Admin_Dashboard_System SHALL display four summary cards: Total orders, New today, In progress, and Ready to collect, each with its numeric value and caption.
4. WHEN the Admin Dashboard loads, THE Admin_Dashboard_System SHALL display an "Orders by stage" section with one card per Order_Stage, each showing the stage name, its count, and a colored progress bar.
5. WHEN the Admin Dashboard loads, THE Admin_Dashboard_System SHALL display a "Recent orders" table with columns Order, Customer (name and phone), Item, Measurement, Status, and Due date.
6. WHEN a user selects "View all" in the Recent orders section, THE Admin_Shell SHALL navigate to the Admin Orders destination.
7. WHILE the Narrow_Layout is active, THE Admin_Dashboard_System SHALL present the four summary cards in a two-by-two grid and SHALL present an "Orders to update" list where each card shows the order summary, its current stage, and a button to advance it to the next stage.
8. WHERE a Measurement_State is "Not sure", THE Admin_Dashboard_System SHALL visually distinguish it from "Entered" in the Recent orders table.

### Requirement 3: Orders management and status updates

**User Story:** As an admin, I want to browse orders by stage and advance an order through its lifecycle, so that I can keep order statuses current.

#### Acceptance Criteria

1. WHEN the Admin Orders screen loads, THE Admin_Orders_System SHALL display Stage_Filter chips for All and each Order_Stage, each labeled with the number of orders in that stage.
2. WHEN a user selects a Stage_Filter other than All, THE Admin_Orders_System SHALL display only orders whose current Order_Stage equals the selected filter.
3. WHEN the Stage_Filter is All, THE Admin_Orders_System SHALL display every order.
4. WHEN a user selects an order from the list, THE Admin_Orders_System SHALL display that order's detail panel including order number, placed date, item, amount payable at shop, customer name, phone, address, a measurements note, and a status update section.
5. WHILE an order is selected, THE Admin_Orders_System SHALL render the status update section as a vertical list of the six Order_Stage values with the current stage indicated.
6. WHILE an order's current stage is not the final stage ("All set"), THE Admin_Orders_System SHALL display a primary action button labeled to advance the order to the next Order_Stage (e.g. "Mark as 'Measurement done'").
7. WHEN a user activates the advance button, THE Admin_Orders_System SHALL update the selected order's current stage to the next Order_Stage and refresh the list, chip counts, and detail panel to reflect the change.
8. WHILE an order's current stage is the final stage ("All set"), THE Admin_Orders_System SHALL NOT display an advance button.
9. WHERE no order is selected on a Wide_Layout, THE Admin_Orders_System SHALL select the first order in the current filtered list by default.

### Requirement 4: Product catalog management

**User Story:** As an admin, I want to view, search, add, and edit products, so that I can keep the shop's catalog up to date.

#### Acceptance Criteria

1. WHEN the Admin Products screen loads, THE Admin_Products_System SHALL display a table with columns Product (icon and name), Category, Price, Stitch time, Rating, Photos, Visibility, and a per-row Edit action.
2. WHEN a user enters a product search query, THE Admin_Products_System SHALL display only products whose name contains the query, matched case-insensitively.
3. WHEN the product search query is empty, THE Admin_Products_System SHALL display every product.
4. WHERE a product's Product_Visibility is "Live", THE Admin_Products_System SHALL render a "Live" badge, and WHERE it is "Hidden", THE Admin_Products_System SHALL render a "Hidden" badge.
5. WHEN a user selects "Add product", THE Admin_Products_System SHALL open the Add/Edit Product form with empty fields.
6. WHEN a user selects a row's "Edit" action, THE Admin_Products_System SHALL open the Add/Edit Product form pre-filled with that product's values.
7. THE Add/Edit Product form SHALL present fields for name, category, price, stitch time, rating, photo count, visibility, and description.
8. IF a user submits the Add/Edit Product form with an empty name or a non-positive price, THEN THE Admin_Products_System SHALL display an inline validation message and SHALL NOT save.
9. WHEN a user submits a valid Add/Edit Product form, THE Admin_Products_System SHALL add or update the product in the in-memory catalog and return to the Admin Products screen with the change reflected.
10. WHEN a user cancels the Add/Edit Product form, THE Admin_Products_System SHALL return to the Admin Products screen without changes.

### Requirement 5: Customer directory

**User Story:** As an admin, I want to browse and search customers, so that I can look up who has ordered and how to reach them.

#### Acceptance Criteria

1. WHEN the Admin Customers screen loads, THE Admin_Customers_System SHALL display a table with columns Customer (initials avatar and name), Mobile, Email, Gender, Type, Orders, and Last order.
2. WHERE a customer has no email, THE Admin_Customers_System SHALL render an em dash ("—") in the Email column.
3. WHERE a customer's Customer_Type is "Guest", THE Admin_Customers_System SHALL render a "Guest" badge, and WHERE it is "Registered", THE Admin_Customers_System SHALL render a "Registered" badge.
4. WHEN a user enters a query in the "Name or mobile" search field, THE Admin_Customers_System SHALL display only customers whose name or mobile contains the query, matched case-insensitively.
5. WHEN the customer search query is empty, THE Admin_Customers_System SHALL display every customer.

### Requirement 6: Visual design and data backing

**User Story:** As a developer, I want the admin screens to reuse the app's theme and mock-repository pattern, so that the UI is consistent and ready to wire to Firebase later.

#### Acceptance Criteria

1. THE Admin_App SHALL style all screens using the existing `AppColors`, `AppSpacing`, and `AppTheme` tokens, using the brand red for primary actions, selected states, and progress accents.
2. THE Admin_App SHALL render every screen from in-memory mock data exposed through an Admin_Data_Layer repository interface.
3. THE Admin_Data_Layer SHALL define a repository interface in the domain layer and provide a mock implementation seeded with the sample orders, products, and customers shown in the designs.
4. THE Admin_App SHALL map each Order_Stage to a distinct status color consistent with the existing status color conventions.
5. WHERE an Admin_App screen reuses an existing shared widget (e.g. status badge, filter chips, section card, primary button), THE Admin_App SHALL use that widget rather than introduce a duplicate.
