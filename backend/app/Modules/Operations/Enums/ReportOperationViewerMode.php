<?php

declare(strict_types=1);

namespace App\Modules\Operations\Enums;

enum ReportOperationViewerMode: string
{
    case Full = 'full';
    case Customer = 'customer';
    case SecondOrderRecipient = 'second_order_recipient';
}
