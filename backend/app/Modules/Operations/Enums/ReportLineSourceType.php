<?php

namespace App\Modules\Operations\Enums;

enum ReportLineSourceType: string
{
    case PRICE_LIST = 'PRICE_LIST';
    case CUSTOM     = 'CUSTOM';
}
