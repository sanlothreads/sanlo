# Requirements Document

## Introduction

Sanlo is a Flutter mobile application for ordering custom-stitched clothing. Customers sign in via mobile OTP (or continue as a guest, or create an email-based account), browse a catalog of tailoring styles, view style details, and place a multi-step order (their details → measurements → review) that is tracked through a stitching timeline until it is ready for pickup at the shop. There is no online payment; customers pay by cash or UPI at the shop.

These requirements are derived from the approved design document and serve as the specification for a fresh Flutter build. The app comprises 11 screens: Sign in/Welcome, Sign up, Home, My orders, Profile, Product details, Order step 1 (Your details), Order step 2 (Measurements), Order step 3 (Review), Order placed, and Order tracking. All screens render placeholder images and are backed by in-memory mock data exposed through repository interfaces so the data layer can later be swapped for real API implementations without touching presentation or domain code.

## Glossary

- **Sanlo_App**: The overall Flutter mobile application under specification.
- **Auth_System**: The component responsible for sign-in, OTP handling, guest sessions, and account creation (backed by `AuthBloc` and `AuthRepository`).
- **Catalog_System**: The component responsible for loading categories and products and applying filtering and search on the Home screen (backed by `HomeCubit` and `ProductRepository`).
- **Product_Details_System**: The component responsible for loading and displaying a single style's details (backed by `ProductDetailsCubit`).
- **Order_Flow_System**: The component managing the three-step place-order state machine (backed by `PlaceOrderBloc` and `OrderRepository`).
- **Orders_System**: The component responsible for listing a customer's active and completed orders (backed by `OrdersCubit`).
- **Order_Tracking_System**: The component responsible for loading an order's header and stitching timeline (backed by `OrderTrackingCubit`).
- **Profile_System**: The component responsible for loading the user profile, stats, and personal details (backed by `ProfileCubit` and `ProfileRepository`).
- **Data_Layer**: The repository interfaces and their mock implementations (`MockAuthRepository`, `MockProductRepository`, `MockOrderRepository`, `MockProfileRepository`) plus the in-memory data sources.
- **Navigation_System**: The `go_router` configuration driving all screen transitions, including the 3-tab bottom-navigation shell and the order sub-flow.
- **OTP**: A one-time passcode sent to a mobile number to authenticate a user; the mock expected code is `0000`.
- **Guest_Session**: An authenticated session with no credentials, where `AuthUser.isGuest == true`.
- **Order_Draft**: The in-progress order aggregate (product, optional customer details, optional measurements) carried across the three order steps.
- **Category_Filter**: The selectable chip set with values All, Women, Men, and Kids.
- **Timeline_Step**: A single node in the order tracking timeline with a stage, label, state (done/current/pending), and optional timestamp.
- **Order_Bucket**: The grouping of orders into Active or Completed.

## Requirements

### Requirement 1: Authentication and onboarding

**User Story:** As a new or returning customer, I want to sign in with my mobile number, continue as a guest, or create an account, so that I can access the app in the way that suits me.

#### Acceptance Criteria

1. WHEN a user submits a valid 10-digit Indian mobile number on the Sign in screen, THE Auth_System SHALL request an OTP and transition to the OTP-entry state.
2. IF a user submits a mobile number that is not a valid 10-digit Indian mobile number, THEN THE Auth_System SHALL display the inline message "Enter a valid 10-digit mobile" and SHALL NOT request an OTP.
3. WHEN a user submits an OTP code equal to the session's expected code, THE Auth_System SHALL mark the user as authenticated and navigate to the Home screen.
4. IF a user submits an OTP code that does not equal the session's expected code, THEN THE Auth_System SHALL display the message "Incorrect code" and SHALL remain unauthenticated.
5. IF an OTP code is submitted before an OTP session has been requested, THEN THE Auth_System SHALL NOT mark the user as authenticated.
6. WHEN a user selects "Continue as guest" or "Skip" on the Sign in screen, THE Auth_System SHALL start a Guest_Session with `isGuest == true` and navigate to the Home screen.
7. WHEN a user selects "Create an account" on the Sign in screen, THE Navigation_System SHALL navigate to the Sign up screen.
8. THE Sign up screen SHALL present first name, last name, mobile, email, and gender input fields.
9. WHEN a user completes the Sign up form and selects "Create account", THE Auth_System SHALL create the account and navigate the authenticated user to the Home screen.
10. WHEN a user selects the "Sign in" link on the Sign up screen, THE Navigation_System SHALL navigate to the Sign in screen.
11. WHILE a user is authenticated, THE Auth_System SHALL preserve the user identity until an authentication reset occurs.

### Requirement 2: Catalog and Home browsing

**User Story:** As a customer, I want to browse and search a catalog of tailoring styles by category, so that I can find the style I want to order.

#### Acceptance Criteria

1. WHEN the Home screen loads, THE Catalog_System SHALL display a greeting, a search field, the Category_Filter chips (All, Women, Men, Kids), a promotional banner, and a grid of popular products.
2. WHEN a user selects a Category_Filter other than All, THE Catalog_System SHALL display only products whose category equals the selected filter.
3. WHEN a user enters a search query, THE Catalog_System SHALL display only products whose name contains the query, matched case-insensitively, among those passing the active Category_Filter.
4. WHEN the Category_Filter is All and the search query is empty, THE Catalog_System SHALL display every product in the catalog.
5. WHEN a guest user views the Home screen, THE Catalog_System SHALL display a sign-in button in the Home header.
6. WHEN a user selects the sign-in button on the Home screen, THE Navigation_System SHALL navigate to the Sign in screen.
7. WHEN a user taps a product card in the grid, THE Navigation_System SHALL navigate to the Product details screen for that product's identifier.
8. THE Sanlo_App SHALL display a bottom navigation bar with Home, My orders, and Profile tabs on the Home, My orders, and Profile screens.
9. WHEN a user selects a bottom navigation tab, THE Navigation_System SHALL display the corresponding tab screen while preserving each tab's navigation stack.

### Requirement 3: Product details

**User Story:** As a customer, I want to view the details of a style, so that I can decide whether to order it.

#### Acceptance Criteria

1. WHEN the Product details screen loads for a product identifier, THE Product_Details_System SHALL load and display that product's style detail.
2. THE Product details screen SHALL display an image carousel placeholder, selectable variant thumbnails, the category label, the type label, and the product rating.
3. THE Product details screen SHALL display information chips showing the price, the ready-in-days duration, and the payment label.
4. THE Product details screen SHALL display an "About this style" description and an included-items checklist.
5. WHEN a user selects a variant thumbnail, THE Product_Details_System SHALL update the selected variant index to the chosen variant.
6. IF the requested product identifier does not exist, THEN THE Product_Details_System SHALL display a "Not found" state with a back action.
7. WHEN a user selects "Order now", THE Order_Flow_System SHALL start a new Order_Draft for the displayed product AND THE Navigation_System SHALL navigate to Order step 1 (Your details).

### Requirement 4: Place-order flow

**User Story:** As a customer, I want to place an order through a guided three-step flow, so that I can provide my details and measurements and confirm before ordering.

#### Acceptance Criteria

1. WHEN a user submits customer details in Order step 1, THE Order_Flow_System SHALL store the details in the Order_Draft and advance to Order step 2 (Measurements).
2. THE Order step 1 screen SHALL present full name and mobile as required fields and email and address as optional fields.
3. WHERE a user selects "Not sure" for measurements in Order step 2, THE Order_Flow_System SHALL accept a measurement set with `knowsMeasurements == false` and no numeric fields and SHALL allow the order to proceed.
4. WHERE a user selects "I know" for measurements in Order step 2, THE Order step 2 screen SHALL present in-inches measurement fields and an optional design-notes field.
5. WHEN a user submits measurements in Order step 2, THE Order_Flow_System SHALL store the measurements in the Order_Draft and advance to Order step 3 (Review).
6. WHEN a user selects an edit action on the Review step, THE Order_Flow_System SHALL return to the corresponding step while preserving the previously captured details and measurements in the Order_Draft.
7. WHEN a user selects "Place order" on the Review step AND the Order_Draft has both customer details and measurements, THE Order_Flow_System SHALL place the order and navigate to the Order placed screen.
8. IF a user selects "Place order" while the Order_Draft is missing customer details or measurements, THEN THE Order_Flow_System SHALL NOT place the order and SHALL display the message "Complete all steps first".
9. WHEN an order is placed successfully, THE Order_Flow_System SHALL produce an order whose product equals the Order_Draft product and whose identifier matches the `#SN-####` format.
10. IF placing the order fails, THEN THE Order_Flow_System SHALL return to the Review step and display the message "Could not place order, try again".
11. IF a user navigates to Order step 2 or Order step 3 without an Order_Draft that has a product, THEN THE Navigation_System SHALL redirect the user to the Home screen.
12. WHEN the Order placed screen is shown, THE Navigation_System SHALL offer a "Track order" action to the Order tracking screen and a "Back to home" action to the Home screen.

### Requirement 5: My orders

**User Story:** As a customer, I want to see my active and completed orders, so that I can review their status and progress.

#### Acceptance Criteria

1. WHEN the My orders screen loads, THE Orders_System SHALL display Active and Completed tabs.
2. WHEN a user selects the Active tab, THE Orders_System SHALL display only orders in the Active Order_Bucket.
3. WHEN a user selects the Completed tab, THE Orders_System SHALL display only orders in the Completed Order_Bucket.
4. WHERE the current user is a guest, THE My orders screen SHALL display a sign-in information banner.
5. THE My orders screen SHALL display each order as a card showing a status badge, a progress indicator, the next step, and the amount payable at the shop.
6. WHEN a user taps an order card, THE Navigation_System SHALL navigate to the Order tracking screen for that order's identifier.

### Requirement 6: Order tracking

**User Story:** As a customer, I want to track the stitching progress of an order and contact the shop, so that I know when my order will be ready.

#### Acceptance Criteria

1. WHEN the Order tracking screen loads for an order identifier, THE Order_Tracking_System SHALL display a header card for the order and a six-stage timeline.
2. THE Order_Tracking_System SHALL render the timeline such that for a non-completed order exactly one Timeline_Step has state `current`, and for a completed order zero steps have state `current` and all steps have state `done`, with done and current steps preceding pending steps in the fixed stage order (Order placed, Measurement done, Stitching started, Stitching finished, Final touch-up, All set), and with every done or current step having a timestamp and every pending step having no timestamp.
3. WHEN a user selects "Call the shop", THE Order_Tracking_System SHALL launch a `tel:` action for the shop's phone number.
4. IF the device cannot launch the `tel:` action, THEN THE Order_Tracking_System SHALL take no action and leave the screen unchanged.
5. IF the requested order identifier does not exist, THEN THE Order_Tracking_System SHALL display a "Not found" state with a back action.

### Requirement 7: Profile

**User Story:** As a customer, I want to view my profile with my stats and personal details, so that I can see my account information.

#### Acceptance Criteria

1. WHEN the Profile screen loads, THE Profile_System SHALL display a profile header, order stats (Total orders, In progress, Ready), and a personal details section (name, mobile, email, gender).
2. WHEN a user selects the sign-in action on the Profile screen, THE Navigation_System SHALL navigate to the Sign in screen.
3. WHERE profile editing is enabled, THE Profile_System SHALL allow updating the personal details and SHALL persist the updated profile through the Profile_System.

### Requirement 8: Data layer and repository abstraction

**User Story:** As a developer, I want the data layer to be abstracted behind repository interfaces with mock implementations, so that the mock data can later be swapped for real API implementations without changing presentation or domain code.

#### Acceptance Criteria

1. THE Data_Layer SHALL expose `AuthRepository`, `ProductRepository`, `OrderRepository`, and `ProfileRepository` as interfaces that the mock implementations satisfy, and all presentation and domain code SHALL depend only on those interfaces and never reference concrete mock classes.
2. THE Data_Layer SHALL seed an in-memory catalog of six products with the identifiers, categories, names, types, ratings, ready-in-days, and prices specified in the design.
3. THE Data_Layer SHALL seed at least one active order including `#SN-1048` and at least one completed order, each exposed through the appropriate Order_Bucket.
4. THE Data_Layer SHALL seed a six-stage timeline for order tracking using the stages Order placed, Measurement done, Stitching started, Stitching finished, Final touch-up, and All set.
5. THE Data_Layer SHALL render all images as placeholder images and SHALL require no bundled image assets.
6. WHEN the mock authentication repository verifies an OTP, THE Data_Layer SHALL treat the fixed code `0000` as the only correct code for a session.
