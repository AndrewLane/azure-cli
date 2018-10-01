# --------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.
# --------------------------------------------------------------------------------------------

import os
import sys

with open(os.path.join(os.getcwd(), 'src', 'azure-cli', 'azure', 'cli', '__init__.py')) as fq:
    for line in fq.readlines():
        if '__version__' in line:
            sys.stdout.write(line.replace(" ", "").replace("\"", "")[12:].strip())
            break
