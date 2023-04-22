#int dbid = this._attachmentUnit.AttachmentRepository.GetDbid(attachmentUid);
#int num1 = 1000000;
#long num2 = (long) checked ((int) Math.Round(unchecked ((double) dbid + 0.5 * (double) num1 + 1E-06 / (double) num1)) * num1);
#int num3 = 10000;
#long num4 = (long) checked ((int) Math.Round(unchecked (((double) dbid + 0.5 * (double) num3) / (double) num3 + 1E-06)) * num3);
#int num5 = 100;
#long num6 = (long) checked ((int) Math.Round(unchecked (((double) dbid + 0.5 * (double) num5) / (double) num5 + 1E-06)) * num5);
#return string.Format("{0}\\{1}\\{2}\\{3}", (object) num2, (object) num4, (object) num6, (object) attachmentUid.ToString());

$DBid = 2123729
$num1 = 1000000
$num2 = [Math]::Round($dbid + 0.5 * $num1 + 1E-06 / $num1) * $num1
$num3 = 10000
$num4 = [Math]::Round((($dbid + 0.5 * $num3) / $num3 + 1E-06)) * $num3
$num5 = 100
$num6 = [Math]::Round((($dbid + 0.5 * $num5) / $num5 + 1E-06)) * $num5

Write-Host "$num2 / $num4 / $num6 / attid"

#$path = $num2.ToString()
