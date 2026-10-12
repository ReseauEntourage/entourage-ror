---
name: rails-upgrade-prep
description: Audit the current Rails app and produce a readiness report for upgrading to the next Rails minor version. Use when the user asks to prepare for a Rails upgrade, assess upgrade readiness, or check what blockers exist.
---

You are preparing an upgrade readiness report for this Rails application.

Steps to follow in order:

1. Read `Gemfile.lock` and identify the current Rails version and Ruby version.
2. Determine the target Rails version (the next minor release, unless the user specifies otherwise).
3. Check the target version's minimum Ruby requirement from the Rails upgrade guides.
4. Run `bundle outdated --only-explicit` and note gems that have major version bumps available.
5. Run `bundle exec bundle-audit check --update` if the gem is available; flag any CVEs.
6. Grep the codebase for deprecation warnings currently being raised (look for `ActiveSupport::Deprecation`, silenced deprecations, and comment markers).
7. List any frozen or version-pinned gems that would block the upgrade.
8. Check the test suite:
   - Does `bin/rspec` or `bin/rails test` pass?
   - Are there skipped or pending tests relevant to the upgrade surface area?
9. Produce a markdown report with sections:
   - Current state (Rails/Ruby versions, test status)
   - Blockers (things that must change before the upgrade)
   - Risks (things that might break, ranked by likelihood)
   - Recommended sequence (what to upgrade, in what order)

Do not modify any files. This skill is read-only and produces a report.
