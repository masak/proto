use v6;
use Test;

# [T] Install-ST a tested project: Succeed.

# [T] Install-ST an untested project: Don't test, install.

# [T] Install-ST an unbuilt project: Build, don't test, install.

# [T] Install-ST an unbuilt project; build fails. Fail.

# [T] Install-ST an unfetched project: Fetch, build, don't test, install.

# [T] Install-ST an unfetched project; fetch fails. Fail.

# [T] Install-ST an unfetched project; build fails. Fail.

# [T] Install-ST a project with dependencies: Install-ST dependencies too.

# [T] Install-ST a project with circular dependencies: Fail.

# [T] Install-ST a project whose direct dependency fails: Fail.

# [T] Install-ST a project whose indirect dependency fails: Fail.
