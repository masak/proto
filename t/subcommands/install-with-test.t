use v6;
use Test;

# [T] Install a tested project: Succeed.

# [T] Install an untested project: Test, install.

# [T] Install an untested project; testing fails. Fail.

# [T] Install an unbuilt project: Build, test, install.

# [T] Install an unbuilt project; build fails. Fail.

# [T] Install an unbuilt project; testing fails. Fail.

# [T] Install an unfetched project: Fetch, build, test, install.

# [T] Install an unfetched project; fetch fails. Fail.

# [T] Install an unfetched project; build fails. Fail.

# [T] Install an unfetched project; testing fails. Fail.

# [T] Install a project with dependencies: Install dependencies too.

# [T] Install a project with circular dependencies: Fail.

# [T] Install a project whose direct dependency fails: Fail.

# [T] Install a project whose indirect dependency fails: Fail.
