use v6;
use Test;

# [T] Build a project: Succeed.

# [T] Build an unfetched project: Fetch, build.

# [T] Build an unfetched project; fetch fails. Fail.

# [T] Build a project; a build error occurs: Fail.

# [T] Build a project with dependencies: Build dependencies first.

# [T] Build a project with circular dependencies: Fail.

# [T] Build a project whose direct dependency fails: Fail.

# [T] Build a project whose indirect dependency fails: Fail.
