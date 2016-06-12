=======
Swiffer
=======

Swiffer is pre-commit hook for Git for ensuring a minimal amount of
code documentation quality. Currently it only supports Swift.

.. note::

   Swiffer requires Swift 3 which (at the time of writing) is still unreleased.
   It should also be noted that Swiffer is only compiled and tested under Linux
   so far and might not even compile under Mac OS X. Any help with testing or
   porting would be appreciated.


Building from source
====================

Simply execute ``swift build``. Requires Swift 3.


Influences
==========

Swiffer is heavily inspired by the paper `How to build static checking systems
using orders of magnitude less code
<http://web.stanford.edu/~mlfbrown/paper.pdf>`_ by Brown et al.


License
=======

MIT/Expat. See LICENSE for details.

Swiffer also uses some code from the following projects:

* The Swift Package Manager, which is released under the APLv2 license::

    Copyright 2015 - 2016 Apple Inc. and the Swift project authors. Licensed under
    Apache License v2.0 with Runtime Library Exception.

* TryParsec, which is Copyright (c) 2016 Yasuhiro Inami and released under a MIT
  license.
