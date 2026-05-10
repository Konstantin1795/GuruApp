<?php

namespace App\Modules\Operations\Enums;

enum TransferTargetType: string
{
    case PERSONAL_BALANCE = 'PERSONAL_BALANCE';
    case ACCOUNTABLE_BALANCE = 'ACCOUNTABLE_BALANCE';
}
