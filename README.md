# Laundry POS (hosted database version)

Static web app (GitHub Pages) + Supabase (free hosted database and logins).
Orders and prices are shared live across every phone, tablet and PC that signs in.

## Setup (about 15 minutes)

1. **Create a Supabase project.** Go to supabase.com, sign up, click New project, pick a name,
   a database password (save it) and the region closest to you.
2. **Create the tables.** In the project, open SQL Editor > New query, paste everything from
   `setup.sql`, and click Run. It should say "Success".
3. **Create your owner login.** Authentication > Users > Add user > Create new user.
   Enter your email and a password and tick Auto Confirm User.
   The FIRST account created becomes the admin (can edit prices and delete orders).
4. **Add staff logins.** Same screen, one account per cashier. They become cashiers
   (can add orders, change status, collect payment; cannot edit prices or delete).
5. **Turn off public sign-ups (important).** Authentication > Sign In / Providers
   (or Settings) > switch OFF "Allow new users to sign up". Otherwise a stranger who finds
   your site could create an account and see your orders.
6. **Copy your keys.** Project Settings > API. Copy the Project URL and the anon / publishable key.
   Open `config.js` and paste them in. Never paste the service_role / secret key anywhere.
7. **Put it online.** Upload all the files (not the folder) to a public GitHub repository,
   then Settings > Pages > Branch: main, folder: / (root) > Save.
   Your site is at https://YOUR-USERNAME.github.io/REPO-NAME/
8. Open the site, sign in, and install it to the home screen if you like.

## Notes
- The anon key in config.js is meant to be public. The data is protected by the login and by the
  row level security rules in setup.sql, so only people with an account can read or write anything.
- Order numbers are assigned by the database, so two devices can never get the same number.
- The Orders tab shows the latest 300 orders. The Sales tab can look up any date.
- Requires an internet connection to save orders. Free Supabase projects pause after about a week
  of no use; open the Supabase dashboard and click Restore if that happens.
- To make someone else an admin: Table Editor > profiles > change their role to admin.
