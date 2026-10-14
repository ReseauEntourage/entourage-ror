---
name: update-libraries
description: Update the LIBRARIES.md file at the root of the entourage-back-preprod repo to reflect the current state of the Gemfile. Use this skill when the user asks to "update libraries", "sync LIBRARIES.md", "update the library doc", or when the Gemfile has changed and LIBRARIES.md needs refreshing.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
---

Update the `LIBRARIES.md` file at the root of the `entourage-back-preprod` repo to reflect the current state of the `Gemfile`.

## Steps

1. **Read the Gemfile and Gemfile.lock** to collect the full list of gems with their version constraints and resolved versions:
   - Parse all `gem` entries from `Gemfile`, noting their group (default/production, `:development`, `:test`, `:development, :test`)
   - Use `Gemfile.lock` for exact resolved versions (the `DEPENDENCIES` and `GEM` sections)
   - Note any git-sourced gems (e.g. `git: 'https://...'`)

2. **Detect changes** by comparing the gems and versions found against what is currently documented in `LIBRARIES.md`:
   - New gems not yet listed → add them
   - Gems removed from `Gemfile` → remove their entries
   - Version bumps → update the version and release date fields
   - No changes → state so and exit

3. **For any new or updated gem**, search the source files (`.rb`, `.rake`) in `app/`, `lib/`, `config/`, `spec/` to understand how it is used, and write or update the entry following this format:

   ```
   ### `gem-name`

   | | |
   |---|---|
   | **Version** | `x.y.z` |
   | **Release date** | Month YYYY (approximate) |
   | **Changelog / Rubygems** | [rubygems.org/gems/gem-name](https://rubygems.org/gems/gem-name) |

   One-sentence description of what the gem does.

   **Used in:** file(s) / area(s) of the app and what for.

   **Alternatives:** comma-separated list of popular alternatives.
   ```

4. **Place each entry under the correct thematic group.** Use the following groups (add new ones if needed):

   - Rails Core & Server
   - Database
   - Asset Pipeline & Frontend
   - Models & Serialization
   - Background Jobs & Caching
   - Authentication & Security
   - API Clients & Integrations
   - Push Notifications & SMS
   - Email
   - Storage (AWS / Cloud)
   - Search & Filtering
   - Geolocation
   - Monitoring & Logging
   - Utilities
   - Development & Code Quality *(dev)*
   - Testing *(test)*

5. **Rewrite `LIBRARIES.md`** with all changes applied, preserving the existing structure and header. If no `LIBRARIES.md` exists yet, create it with the following header:

   ```markdown
   # Libraries

   This document lists all gems used in the `entourage-back-preprod` Rails application, organized by purpose.

   **Ruby version:** 3.2.0
   **Rails version:** ~> 7.1.0

   ---
   ```

Be precise about versions — use the exact resolved version from `Gemfile.lock` in the **Version** field, and include the version constraint from `Gemfile` as a comment when it differs (e.g. `4.2.1` *(Gemfile: `~> 4`)*). For git-sourced gems, note the repository URL instead of a version.
