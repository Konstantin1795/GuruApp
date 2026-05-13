<?php

declare(strict_types=1);

namespace App\Modules\Operations\Services;

use App\Modules\Operations\Enums\ReportOperationViewerMode;
use App\Modules\Operations\Models\ReportOperation;
use App\Modules\Projects\Models\ProjectParticipant;

final class ReportOperationViewerModeResolver
{
    public function resolve(?ProjectParticipant $viewer, ReportOperation $report): ReportOperationViewerMode
    {
        if ($viewer === null) {
            return ReportOperationViewerMode::Full;
        }

        if ((int) $viewer->id === (int) $report->customer_project_participant_id) {
            return ReportOperationViewerMode::Customer;
        }

        if ((int) $viewer->id === (int) $report->recipient_project_participant_id
            && strtolower((string) $viewer->level) === 'second') {
            return ReportOperationViewerMode::SecondOrderRecipient;
        }

        return ReportOperationViewerMode::Full;
    }
}
