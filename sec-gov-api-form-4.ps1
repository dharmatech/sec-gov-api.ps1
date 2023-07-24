
Param($cik, $n = 10)

# ------------------------------------------------------------
function get-recent-filings ([string]$cik)
{
    $cik_padded = $cik.PadLeft(10, '0')

    # $SEC_GOV_USER_AGENT should be set to something like this:
    # 
    # 'company-name   contact@company.com'

    $result = Invoke-RestMethod "https://data.sec.gov/submissions/CIK$cik_padded.json" -Headers @{ 'User-Agent' = $SEC_GOV_USER_AGENT } 

    for ($i = 0; $i -lt $result.filings.recent.accessionNumber.Count; $i++)
    {

        $a = $result.filings.recent.accessionNumber[$i] -replace '-', ''
        $b = $result.filings.recent.primaryDocument[$i]
    
        $url = "https://www.sec.gov/Archives/edgar/data/$($result.cik)/$a/$b"

        $primary_document_components = $result.filings.recent.primaryDocument[$i] -split '/'

        $c = $primary_document_components[-1]

        $xml = "https://www.sec.gov/Archives/edgar/data/$($result.cik)/$a/$c"

        [PSCustomObject]@{
            accessionNumber       = $result.filings.recent.accessionNumber[$i]
            filingDate            = $result.filings.recent.filingDate[$i]
            reportDate            = $result.filings.recent.reportDate[$i]
            acceptanceDateTime    = $result.filings.recent.acceptanceDateTime[$i]
            act                   = $result.filings.recent.act[$i]
            form                  = $result.filings.recent.form[$i]
            fileNumber            = $result.filings.recent.fileNumber[$i]
            filmNumber            = $result.filings.recent.filmNumber[$i]
            items                 = $result.filings.recent.items[$i]
            size                  = $result.filings.recent.size[$i]
            isXBRL                = $result.filings.recent.isXBRL[$i]
            isInlineXBRL          = $result.filings.recent.isInlineXBRL[$i]
            primaryDocument       = $result.filings.recent.primaryDocument[$i]
            primaryDocDescription = $result.filings.recent.primaryDocDescription[$i]        
            xml                   = $xml
            url                   = $url
        }   
    }      
}

# ------------------------------------------------------------

# $filings = get-recent-filings 1318605; $filings_tsla = $filings

# $filings = get-recent-filings 857156;  $filings_schw = $filings

# $fields = @(
#     # 'accessionNumber'
#     'filingDate'
#     'reportDate'
#     'acceptanceDateTime'
#     'act'
#     'form'
#     'fileNumber'
#     'filmNumber'
#     'items'
#     'size'
#     'isXBRL'
#     'isInlineXBRL'
#     # 'primaryDocument'
#     'primaryDocDescription'
#     'xml'
#     # 'url'
# )

# ------------------------------------------------------------
# Form 4 data
# ------------------------------------------------------------



# $filings | Select-Object -First 40 | ft *


# $filings | ? form -EQ 4 | Sort-Object filingDate -Descending | Select-Object -First 40 | ft *

# $filings | ? form -EQ 4 | Select-Object -First 40 | ft *

# $filing = $filings | ? acceptanceDateTime -EQ '2023-06-27T17:48:16.000Z'

# $filing = $filings_form_4[0]

function get-form-4-data ($cik, $n = 10)
{
    Write-Host 'Retrieving filings' -ForegroundColor Yellow
    $filings = get-recent-filings $cik

    $filings_form_4 = $filings | ? form -EQ '4' | Select-Object -First $n


    Write-Host 'Retrieving form 4 data for each filing'
    foreach ($filing in $filings_form_4)
    {
        Write-Host '.' -ForegroundColor Yellow -NoNewline
        $result_xml = Invoke-RestMethod $filing.xml -Headers @{ 'User-Agent' = $SEC_GOV_USER_AGENT } 
    
        $filing | Add-Member -MemberType NoteProperty -Name xml_data -Value $result_xml -Force
    }



    $table = foreach ($filing in $filings_form_4)
    {
        $transactions = @($filing.xml_data.ownershipDocument.nonDerivativeTable.nonDerivativeTransaction)

        if ($transactions.Count -gt 0)
        {
            if ($transactions[0] -ne $null)        
            {    
                foreach ($transaction in $transactions)
                {
                    [PSCustomObject]@{

                        acceptanceDateTime = $filing.acceptanceDateTime

                        securityTitle = $transaction.securityTitle.value
                        transactionDate = $transaction.transactionDate.value
            
                        rptOwnerName = $filing.xml_data.ownershipDocument.reportingOwner.reportingOwnerId.rptOwnerName    
                        officerTitle = $filing.xml_data.ownershipDocument.reportingOwner.reportingOwnerRelationship.officerTitle                        
            
                        # transactionFormType = $transaction.transactionCoding.transactionFormType
                        transactionCode = $transaction.transactionCoding.transactionCode
                        # equitySwapInvolved = $transaction.transactionCoding.equitySwapInvolved
                        transactionAcquiredDisposedCode = $transaction.transactionAmounts.transactionAcquiredDisposedCode.value
            
                        transactionShares = [decimal] $transaction.transactionAmounts.transactionShares.value
                        transactionPricePerShare = [decimal] $transaction.transactionAmounts.transactionPricePerShare.value
            
                        sharesOwnedFollowingTransaction = [decimal]$transaction.postTransactionAmounts.sharesOwnedFollowingTransaction.value
            
                        directOrIndirectOwnership = $transaction.ownershipNature.directOrIndirectOwnership.value
                    }
                }    
            }
        }

        $transactions = @($filing.xml_data.ownershipDocument.derivativeTable.derivativeTransaction)

        if ($transactions.Count -gt 0)
        {
            if ($transactions[0] -ne $null)
            {
                foreach ($transaction in $transactions)
                {
                    [PSCustomObject]@{
                        acceptanceDateTime = $filing.acceptanceDateTime

                        securityTitle = $transaction.securityTitle.value
                        transactionDate = $transaction.transactionDate.value
            
                        rptOwnerName = $filing.xml_data.ownershipDocument.reportingOwner.reportingOwnerId.rptOwnerName    
                        officerTitle = $filing.xml_data.ownershipDocument.reportingOwner.reportingOwnerRelationship.officerTitle                        
            
                        # transactionFormType = $transaction.transactionCoding.transactionFormType
                        transactionCode = $transaction.transactionCoding.transactionCode
                        # equitySwapInvolved = $transaction.transactionCoding.equitySwapInvolved
                        transactionAcquiredDisposedCode = $transaction.transactionAmounts.transactionAcquiredDisposedCode.value
            
                        transactionShares = [decimal] $transaction.transactionAmounts.transactionShares.value
                        transactionPricePerShare = [decimal] $transaction.transactionAmounts.transactionPricePerShare.value
            
                        sharesOwnedFollowingTransaction = [decimal]$transaction.postTransactionAmounts.sharesOwnedFollowingTransaction.value
            
                        directOrIndirectOwnership = $transaction.ownershipNature.directOrIndirectOwnership.value
            
                        # derivative
            
                        conversionOrExercisePrice = [decimal] $transaction.conversionOrExercisePrice.value
            
                        underlyingSecurityTitle = $transaction.underlyingSecurity.underlyingSecurityTitle.value
            
                        underlyingSecurityShares = [decimal] $transaction.underlyingSecurity.underlyingSecurityShares.value
                    }
                }        
            }
        }        
    }

    $table
    
}

$table = get-form-4-data $cik $n

$table_fields = @(
        'acceptanceDateTime'
        'securityTitle'
        'transactionDate'
        'rptOwnerName'
        'officerTitle'
        # 'transactionCode'
        @{ L = 'code'; E = 'transactionCode' }
        # 'transactionAcquiredDisposedCode'
        @{ L = 'ad_code'; E = 'transactionAcquiredDisposedCode' }
        # 'transactionShares'
        @{ L = 'shares'; E = 'transactionShares'; Format = 'N0' }
        # 'transactionPricePerShare'
        @{ L = 'price'; E = 'transactionPricePerShare'; Format = 'N2' }
        # 'sharesOwnedFollowingTransaction'
        @{ L = 'owned_after'; E = 'sharesOwnedFollowingTransaction'; Format = 'N0'; Align = 'right' }
        # 'directOrIndirectOwnership'
        @{ L = 'doio'; E = 'directOrIndirectOwnership' }
        # 'conversionOrExercisePrice'
        @{ L = 'coe_price'; E = 'conversionOrExercisePrice'; Format = 'N2'; Align = 'right' }
        # 'underlyingSecurityTitle'
        @{ L = 'underlyingTitle'; E = 'underlyingSecurityTitle' }
        # 'underlyingSecurityShares'
        @{ L = 'underlyingShares'; E = 'underlyingSecurityShares'; Format = 'N0'; Align = 'right' }
    )
    
$table | ft $table_fields    
# ------------------------------------------------------------
exit
# ------------------------------------------------------------
. .\sec-gov-api-form-4.ps1 1318605 # TSLA
. .\sec-gov-api-form-4.ps1 1045810 -n 20 # NVDA

# $cik = 1318605
# $n = 10