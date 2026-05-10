<?php

namespace App\Modules\Operations\Enums;

enum OperationType: string
{
    case INCOME   = 'INCOME';
    case TRANSFER = 'TRANSFER';
    case REPORT   = 'REPORT';
}
