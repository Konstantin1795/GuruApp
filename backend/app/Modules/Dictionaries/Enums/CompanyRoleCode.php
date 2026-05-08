<?php

namespace App\Modules\Dictionaries\Enums;

enum CompanyRoleCode: string
{
    case OWNER = 'OWNER';
    case PARTNER = 'PARTNER';
    case EMPLOYEE = 'EMPLOYEE';
    case SUPPLIER = 'SUPPLIER';
    case CONTRACTOR = 'CONTRACTOR';
    case CUSTOMER = 'CUSTOMER';
}

