use v6;
use Test;

# [T] Force install an untested project; testing fails. Install anyway.

# [T] Force install an unbuilt project; build fails. Fail.

# [T] Force install an unbuilt project; testing fails. Install anyway.

# [T] Force install an unfetched project; fetch fails. Fail.

# [T] Force install an unfetched project; build fails. Fail.

# [T] Force install an unfetched project; testing fails. Install anyway.

# [T] Force install a project with dependencies: Install dependencies too.

# [T] Force install a project with circular dependencies: Fail.

# [T] Froce install a project whose direct dependency fails: Install anyway.

# [T] Force install a project whose indirect dependency fails: Install anyway.
