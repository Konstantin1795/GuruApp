<?php

namespace App\Modules\Dictionaries\Enums;

enum ProjectRoleCode: string
{
    case PROJECT_HEAD = 'PROJECT_HEAD';
    case PARTNER = 'PARTNER';
    case CUSTOMER = 'CUSTOMER';
    case SUPERVISOR = 'SUPERVISOR';
    case EMPLOYEE = 'EMPLOYEE';
    case SUPPLIER = 'SUPPLIER';
    case CONTRACTOR = 'CONTRACTOR';
}

