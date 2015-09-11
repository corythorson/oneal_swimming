#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib("$Bin/..");
use OnealDB;
use Params;
use PayPal;
use CGI qw(:standard);
use Digest::MD5 qw(md5_hex);
use Data::Dumper;
use Time::Local;

use constant
{
	LESSONTIME		=> 1200,
	NUMSTUDENTS		=> 10,
	NUMTEACHERS		=> 20,
	SALTSTR			=> "This is my salt string.",
	SANDBOX			=> 1,
	CHANGEWINDOW	=> 23 * 60 * 60,
};

my $debug = -e "debug";

my @Mon = ("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
my @Day = ("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");

my $CurrentUser;

sub InitCurrentUser ()
{
	$CurrentUser = undef;
	my $Checksum = cookie("ID");
	$Checksum = "" unless defined($Checksum);
	($Checksum) = split("-", $Checksum);
	return unless $Checksum;
	$CurrentUser = $DB->GetUserByChecksum($Checksum);
}

sub DoDumper
{
	return "<pre>" . Dumper(@_) . "</pre>";
}

sub LoginRedirect ($$)
{
	my ($Checksum, $URL) = @_;
	return "<script>
				\$.cookie('ID', '$Checksum');
				\$(location).attr('search', '$URL');
			</script>";
}

sub Logout ()
{
	return "<script>
				\$.cookie('ID', null);
				\$(location).attr('search', '');
			</script>";
}

sub GetRegistration ()
{
	my @Errors;
	if ($Params->Get("tmp_Register") eq "Submit")
	{
		push(@Errors, "No name given") unless $Params->Get("tmp_Name");
		my $EmailRE = qr(^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$)i;
		push(@Errors, "Invalid email address") unless $Params->Get("tmp_Email") =~ $EmailRE;
		push(@Errors, "Password too short (must be at least 6 chars)") unless length($Params->Get("tmp_Password")) >= 6;
		push(@Errors, "Passwords don't match") unless $Params->Get("tmp_Password") eq $Params->Get("tmp_Confirm");
		my $Phone = $Params->Get("tmp_Phone");
		$Phone =~ s/[^0-9]//g;
		my $PhoneValid = $Phone =~ /^\d{10}$/;
		if ($PhoneValid)
		{
			$Phone =~ s/(\d{3})(\d{3})(\d{4})/$1-$2-$3/;
			$Params->Set("tmp_Phone=$Phone");
		}
		push(@Errors, "Invalid phone number") unless $PhoneValid;

		if (!@Errors)
		{
			my $Checksum = md5_hex(join("-", SALTSTR, $Params->Get("tmp_Email"), $Params->Get("tmp_Password")));
			$DB->CreateUser($Params->Get("tmp_Name"), $Params->Get("tmp_Email"), $Params->Get("tmp_Password"), $Params->Get("tmp_Phone"), $Checksum);
			return LoginRedirect($Checksum, $Params->ToStr());
		}
	}

	return "<h1>Create Account</h1>
			In order to reserve lessons, you must create an account.  Please enter the following:<br><br>
			<form method=post>
				" . $Params->Extra() . "
				" . (@Errors ? "<div id=errors>" . join("<br>", "Error:", @Errors) . "</div>" : "") . "
				<table>
					<tr>
						<td>First & Last Name:</td>
						<td><input class=focus name=tmp_Name value='" . $Params->Get("tmp_Name") . "' size=30></td>
					</tr>
					<tr>
						<td>Email:</td>
						<td><input name=tmp_Email value='" . $Params->Get("tmp_Email") . "' size=30></td>
					</tr>
					<tr>
						<td>Password:</td>
						<td><input type=password name=tmp_Password size=30></td>
					</tr>
					<tr>
						<td>Confirm Password:</td>
						<td><input type=password name=tmp_Confirm size=30></td>
					</tr>
					<tr>
						<td>Phone:</td>
						<td><input name=tmp_Phone value='" . $Params->Get("tmp_Phone") . "' size=30></td>
					</tr>
					<tr>
						<td></td>
						<td align=right><input type=submit name=tmp_Register value='Submit' size=30></td>
					</tr>
				</table>
			</form>";
}

sub GetLogin ()
{
	if (defined($Params->Get("tmp_Login")))
	{
		my $Checksum = $DB->GetUserChecksum($Params->Get("tmp_Email"), $Params->Get("tmp_Password"));
		return LoginRedirect($Checksum, $Params->ToStr()) if defined($Checksum);
	}

	if (defined($Params->Get("tmp_Register")))
	{
		return GetRegistration();
	}

	return "<h1>Log In</h1>
			Please enter your email address and password to log in:
			<form method=post>
				" . $Params->Extra() . "
				<table>
					<tr>
						<td colspan=2></td>
					</tr>
					<tr>
						<td>Email:</td>
						<td><input class=focus name=tmp_Email size=30></td>
					</tr>
					<tr>
						<td>Password:</td>
						<td><input type=password name=tmp_Password size=30></td>
					</tr>
					<tr>
						<td></td>
						<td align=right><input type=submit name=tmp_Login value='Log In'></td>
					</tr>
				</table>
			</form>

			<br>
			If you don't have an account and would like to schedule swimming Lessons, please create one:<br>
			" . $Params->A("Create account", "tmp_Register");
}

sub Uniq
{
	return keys(%{{ map { $_, undef } @_ }});
}

sub Pos
{
	my $Find = shift;
	for (my $ctr = 0; $ctr < @_; $ctr++)
	{
		return $ctr if $Find eq $_[$ctr];
	}
	return undef;
}

sub Sum
{
	my $Sum = 0;
	map { $Sum += $_ } @_;
	return $Sum;
}

sub GetPrintHM ($)
{
	my ($Date) = @_;
	my (undef, $Min, $Hour, undef, undef, undef, undef, undef, undef) = gmtime($Date);
	my $AMPM = $Hour < 12 ? "am" : "pm";
	$Hour = 12 if $Hour == 0;
	$Hour -= 12 if $Hour > 12;
	return sprintf("%02i", $Hour) . ":" . sprintf("%02i", $Min) . " $AMPM";
}

sub GetPrintMDY ($)
{
	my ($Date) = @_;
	my (undef, undef, undef, $Day, $Mon, $Year, $WDay, undef, undef) = gmtime($Date);
	return "$Day[$WDay], $Mon[$Mon] $Day, " . ($Year + 1900);
}

sub GetPrintMDYHM ($)
{
	my ($Date) = @_;
	return GetPrintMDY($Date) . " " . GetPrintHM($Date);
}

sub DayStart ($)
{
	my ($Time) = @_;
	return $Time - $Time % 86400;
}

sub DailyLessons ()
{
	my $Date = DayStart($Params->Get("Start"));

	if (($CurrentUser->{Admin}) && ($Params->Get("tmp_DeleteHour")))
	{
		$DB->DeleteHour($Params->Get("tmp_DeleteHour"));
	}

	my (undef, undef, undef, $Day, $Mon, $Year, $WDay, undef, undef) = gmtime($Date);

	my @Hours = $DB->GetDayHours($Date);
	my @Lessons = $DB->GetDayLessons($Date);
	return "No Hours Available; click " . $Params->A("here", "Page=MonthlyLessons") . " to go back" unless (@Hours) || (@Lessons);

	my ($Prev, $Next) = $DB->GetPrevNextDays($Date);

	my @Students = $DB->NewGetUserStudents($Params->Get("User"));
	my @Teachers = sort { $a->{Name} cmp $b->{Name} } $DB->GetTeachers(Uniq(map { $_->{TeacherID} } @Hours, @Lessons));

	my $Start = (sort { $a <=> $b } (map { $_->{Start} } @Hours), (map { $_->{Time} } @Lessons))[0];
	my $End = (sort { $b <=> $a } (map { $_->{End} } @Hours), (map { $_->{Time} + LESSONTIME } @Lessons))[0];
	my @Times = map { $_ * LESSONTIME } $Start / LESSONTIME .. $End / LESSONTIME;

	my $Stats = GetUserLessonsStats($Params->Get("User"));
	my $CanBook = ($Stats->{Balance} > 0) || ($CurrentUser->{Admin});

	my %Schedule;
	foreach my $Hour (@Hours)
	{
		$Schedule{$Hour->{TeacherID}}{$Hour->{Start}}{HourID} = $Hour->{HourID};
		for (my $Time = $Hour->{Start}; $Time < $Hour->{End}; $Time += LESSONTIME)
		{
			$Schedule{$Hour->{TeacherID}}{$Time}{CanModify} = $CanBook;
			$Schedule{$Hour->{TeacherID}}{$Time}{StudentID} = -1;
		}
	}

	my $Students = $DB->GetStudentsHash(Uniq(map { $_->{StudentID} } @Lessons, @Students));
	my $Users = $DB->GetUsersHash(Uniq(map { $_->{UserID} } values(%$Students)));

	foreach my $Lesson (@Lessons)
	{
		$Schedule{$Lesson->{TeacherID}}{$Lesson->{Time}}{CanModify} = $Students->{$Lesson->{StudentID}}{UserID} == $Params->Get("User");
		$Schedule{$Lesson->{TeacherID}}{$Lesson->{Time}}{StudentID} = $Lesson->{StudentID};
	}

	my @Options = ({ Name => "", StudentID => -1 }, sort { $a->{Name} cmp $b->{Name} } @Students);

	my $Sched = "";
	$Sched .= "Current balance: " . $Stats->{Balance} . " lesson" . ($Stats->{Balance} == 1 ? "" : "s") . ".<br>";
	$Sched .= " (Click " . $Params->A("here", "Page=BuyItems", "tmp_Page=DailyLessons") . " to buy lessons.)";

	my $HTML = "<h1>Schedule Lessons: Daily</h1>
				<form autocomplete='off'>
					$Sched
					<table border=1>
						<tr>
							<td colspan=" . (@Teachers + 1) . ">
								<table>
									<tr>
										<th>" . (defined($Prev) ? $Params->A("«", "Start=$Prev") : "") . "</th>
										<th>$Day[$WDay], $Mon[$Mon] $Day, " . ($Year + 1900) . "</th>
										<th>" . (defined($Next) ? $Params->A("»", "Start=$Next") : "") . "</th>
									</tr>
								</table>
							</td>
						</tr>
						<tr>
							<th>Hour</th>
							" . join("", map { "
							<th>" . $_->{Name} . "</th>
							" } @Teachers) . "
						</tr>";
	foreach my $Time (@Times)
	{
		$HTML .= "		<tr>
							<td>" . GetPrintHM($Time) . "</td>";
		foreach my $Teacher (@Teachers)
		{
			$HTML .= "		<td>";
			if (exists($Schedule{$Teacher->{TeacherID}}{$Time}))
			{
				my $Schedule = $Schedule{$Teacher->{TeacherID}}{$Time};
				if (($CurrentUser->{Admin}) && ($Schedule{$Teacher->{TeacherID}}{$Time}{HourID}))
				{
					$HTML .= $Params->A("[Remove Teacher]", "tmp_DeleteHour=" . $Schedule{$Teacher->{TeacherID}}{$Time}{HourID}) . "<br>";
				}
				if ($Schedule{$Teacher->{TeacherID}}{$Time}{CanModify})
				{
					$HTML .= "	<select id='" . $Teacher->{TeacherID} . "," . $Time . "' class=SetStudent>";
					foreach my $Option (@Options)
					{
						$HTML .= "	<Option value='" . $Option->{StudentID} . "'" . ($Option->{StudentID} == $Schedule->{StudentID} ? " selected='selected'" : "") . ">" . $Option->{Name} . "</Option>";
					}
					$HTML .= "	</select>";
				}
				elsif ($Schedule->{StudentID} != -1)
				{
					my $UserID = $Students->{$Schedule->{StudentID}}{UserID};
					$HTML .= $Params->A("»", "User=$UserID") . " " if $CurrentUser->{Admin};
					$HTML .= $Users->{$UserID}{Name} . "<br>" . $Students->{$Schedule->{StudentID}}{Name};
				}
			}
			$HTML .= "		</td>";
		}
		$HTML .= "		</tr>";
	}
	$HTML .= "		</table>
				</form>
				" . $Params->A("Back to Month", "Page=MonthlyLessons") . "

				<script>
					\$('.SetStudent').change(function(event) {
						var url = '" . $Params->URL("tmp_Reserve=_tmp_reserve_") . "'.replace('_tmp_reserve_', event.target.id + ',' + event.target.value);
						event.target.selectedIndex = 0;
						\$.ajax({
							url: url
						}).done(function() {
							location.reload();
						});
					});
				</script>";
	return $HTML;
}

sub CurrentDay ()
{
	my (undef, undef, undef, $Day, $Mon, $Year, undef, undef) = localtime();
	return timegm(0, 0, 0, $Day, $Mon, $Year);
}

sub MonthlyLessons ()
{
	my $Today = CurrentDay;
	$Params->Set("Start=$Today") unless $Params->Get("Start");

	my $Start = MonthStart($Params->Get("Start"));
	my $End = MonthStart($Start + 86400 * 40);

	my $Available = $DB->GetAvailableDaysHash($Start, $End);
	my $UserLesson = $DB->GetUserLessonDaysHash($Params->Get("User"), $Start, $End);
	@{$Available}{keys(%$UserLesson)} = undef;

	my (undef, undef, undef, undef, $Mon, $Year, $WDay, undef, undef) = gmtime($Start);
	my $Days = ($End - $Start) / 86400;
	my @Days = ({ text => "", time => 0 }) x $WDay;
	push(@Days, map { { text => $_, time => $Start + ($_ - 1) * 86400 } } 1 .. $Days);
	push(@Days, ({ text => "", time => 0 }) x (6 - (@Days  - 1) % 7));
	my @Weeks;
	while (@Days)
	{
		push(@Weeks, [ splice(@Days, 0, 7) ]);
	}
	return "<h1>Schedule Lessons: Monthly</h1>
			<table border=1>
				<tr>
					<th>" . $Params->A("«", "Start=" . MonthStart($Start - 1)) . "</th>
					<th colspan=5>$Mon[$Mon] " . ($Year + 1900) . "</th>
					<th>" . $Params->A("»", "Start=$End") . "</th>
				</tr>
				<tr>
					" . join("", map { "<th>$_</th>" } @Day) . "
				</tr>
				" . join("", map { "
				<tr align=center>
					" . join("", map { "
					<td" . (($_->{time} == $Today) ? " class=today" : "") . ">" . (($_->{time} != 0) ? "
						" . (exists($Available->{$_->{time}}) ? (exists($UserLesson->{$_->{time}}) ? "* " : "") . $Params->A($_->{text}, "Page=DailyLessons", "Start=$_->{time}") : $_->{text}) . "
					" : "") . "
					</td>
					" } @$_) . "
				</tr>
				" } @Weeks) . "
			</table>

			A * indicates you have a lesson on the specified day.";
}

sub LocalTimeAsGMT ()
{
	my ($Sec, $Min, $Hour, $Day, $Mon, $Year, undef, undef) = localtime();
	return timegm($Sec, $Min, $Hour, $Day, $Mon, $Year);
}

sub MonthStart ($)
{
	my ($Date) = @_;
	my (undef, undef, undef, undef, $Mon, $Year, undef, undef) = gmtime($Date);
	return timegm(0, 0, 0, 1, $Mon, $Year);
}

sub ReserveLesson ($$$)
{
	my ($TeacherID, $Time, $StudentID) = @_;
	my $CurrentTime = LocalTimeAsGMT();
	return "Invalid time: $Time" unless $Time % LESSONTIME == 0;
	return "Can't add lessons in the past" unless ($CurrentUser->{Admin}) || ($Time > $CurrentTime);

	my $Lesson = $DB->GetLessonByTeacherAndTime($TeacherID, $Time);
	if (defined($Lesson))
	{
		return "Time out of window" unless ($CurrentUser->{Admin}) || ($Time > $CurrentTime + CHANGEWINDOW);
		return "Can't remove existing Lesson" unless $DB->GetStudentUserID($Lesson->{StudentID}) == $Params->Get("User");
		$DB->RemoveLesson($Lesson->{LessonID});
	}

	if ($StudentID)
	{
		return "Student does not belong to current User: $StudentID" unless $DB->GetStudentUserID($StudentID) == $Params->Get("User");
		return "No Available Balance" unless ($CurrentUser->{Admin}) || (GetUserLessonsStats($Params->Get("User"))->{Balance} > 0);
		$DB->ReserveLesson($TeacherID, $StudentID, $Time);
	}

	return "Success";
}

sub EditItems ()
{
	if ($Params->Get("tmp_ItemID"))
	{
		if ($Params->Get("tmp_SaveItem"))
		{
			my $ItemID = $Params->Get("tmp_ItemID");
			$ItemID = undef if $ItemID eq "new";
			my $Code = $Params->Get("tmp_Code");
			$Code = undef if $Code eq "";
			my $Name = $Params->Get("tmp_Name");
			my $Price = $Params->Get("tmp_Price");
			my $NumLessons = $Params->Get("tmp_NumLessons");

			$DB->SaveOrUpdateItem($ItemID, $Code, $Name, $Price, $NumLessons);
		}
		elsif ($Params->Get("tmp_DeleteItem"))
		{
			$DB->DeleteItem($Params->Get("tmp_ItemID"));
		}
		else
		{
			my $Item;
			my $ItemID = $Params->Get("tmp_ItemID");
			($Item) = values(%{$DB->GetItemsHash($ItemID)}) unless $ItemID eq "new";

			return "<h1>Edit Item</h1>
					<form method=post>
						" . $Params->Extra() . "
						<input type=hidden name=tmp_ItemID value=" . $Params->Get("tmp_ItemID") . ">
						<table>
							<tr>
								<td>Name</td>
								<td><input class=focus name=tmp_Name value='" . $Item->{"Name"} . "'></td>
							</tr>
							<tr>
								<td>Price</td>
								<td><input name=tmp_Price value='" . $Item->{"Price"} . "'></td>
							</tr>
							<tr>
								<td>NumLessons</td>
								<td><input name=tmp_NumLessons value='" . $Item->{"NumLessons"} . "'></td>
							</tr>
							<tr>
								<td>Code</td>
								<td><input name=tmp_Code value='" . $Item->{"Code"} . "'> (Leave blank for generally available items)</td>
							</tr>
							<tr>
								<td colspan=2><input type=submit name=tmp_SaveItem value='Save'><input type=submit name=tmp_DeleteItem value='Delete'></td>
							</tr>
						</table>
					</form>

					" . $Params->A("Cancel", "-tmp_ItemID");
		}
	}

	my @Items = sort { $a->{Name} cmp $b->{Name} } $DB->GetAllItems();
	my $CTR = 0;
	return "<h1>Edit Items for Sale</h1>
			<table border=1>
				<tr>
					<th>#</th>
					<th>Code</th>
					<th>Name</th>
					<th>Price</th>
					<th>NumLessons</th>
					<th>Action</th>
				</tr>
				" . join("", map { "
				<tr>
					<td>" . (++$CTR) . "</td>
					<td>" . $_->{Code} . "</td>
					<td>" . $_->{Name} . "</td>
					<td>" . $_->{Price} . "</td>
					<td>" . $_->{NumLessons} . "</td>
					<td>" . $Params->A("Edit", "tmp_ItemID=" . $_->{ItemID}) . "</td>
				</tr>
				" } @Items) . "
			</table>

			" . $Params->A("New Item", "tmp_ItemID=new");
}

sub EditStudents ()
{
	my ($User) = values(%{$DB->GetUsersHash($Params->Get("User"))});

	my @Students = values(%{$DB->GetUserStudents($User->{UserID})});
	my @Errors;
	if ($Params->Get("tmp_Submit"))
	{
		my %OldStudents = (map { $_->{Name}, $_ } @Students);
		undef @Students;
		my %NewStudents;
		for (my $ctr = 0; ; $ctr++)
		{
			my %Data = (map { $_, scalar $Params->Get("$_$ctr") } "tmp_Student");
			last unless defined($Data{"tmp_Student"});
			next unless $Data{"tmp_Student"};

			push(@Students, \%Data);
			$NewStudents{$Data{tmp_Student}} = 1;
		}
		unless (@Errors)
		{
			my @Common = grep { exists($OldStudents{$_}) } keys(%NewStudents);
			delete(@NewStudents{@Common});
			delete(@OldStudents{@Common});
			foreach my $Student (values(%OldStudents))
			{
				eval { $DB->DeleteStudent($Student->{StudentID}); };
			}
			foreach my $Student (keys(%NewStudents))
			{
				$DB->CreateStudent($User->{UserID}, $Student);
			}

			return "<script>
						\$(location).attr('search', '" . $Params->ToStr("-Page") . "');
					</script>";
		}
	}
	else
	{
		foreach my $Student (@Students)
		{
			$Student->{tmp_Student} = $Student->{Name};
		}
	}

	@Students = sort { $a->{Name} cmp $b->{Name} } @Students;
	while (@Students < NUMSTUDENTS)
	{
		push(@Students, { tmp_Student => "" });
	}

	my (undef, undef, undef, undef, undef, $Year, undef, undef, undef) = gmtime();
	$Year += 1900;

	my $HTML = "<h1>Edit Students</h1>
				Please enter the first names of the students you will be scheduling lessons for:
				<form method=post>
					" . $Params->Extra() . "
					" . (@Errors ? "<div id=errors>" . join("<br>", "Error:", @Errors) . "</div>" : "") . "
					<table border=1>
						<tr>
							<th>#</th>
							<th>First Name</th>
						</tr>";
	for (my $ctr = 0; $ctr < @Students; $ctr++)
	{
		$HTML .= "		<tr>
							<td align=center>" . ($ctr + 1) . "</td>
							<td><input " . ($ctr == 0 ? "class=focus" : "") . " name=tmp_Student$ctr value='" . $Students[$ctr]{tmp_Student} . "'></td>
						</tr>";
	}
	$HTML .= "			<tr>
							<td colspan=2><input type=submit name=tmp_Submit value='Update'></td>
						</tr>
					</table>
				</form>";
	return $HTML;
}

sub EditTeachers ()
{
	if ($Params->Get("tmp_Submit"))
	{
		my %OldTeachers = (map { $_->{Name}, $_ } values(%{$DB->GetAllTeachers()}));
		my %NewTeachers = ( map { $_, undef } grep { $_ } $Params->Get("tmp_Teacher") );
		my @Common = grep { exists($OldTeachers{$_}) } keys(%NewTeachers);
		delete(@NewTeachers{@Common});
		delete(@OldTeachers{@Common});
		foreach my $Teacher (values(%OldTeachers))
		{
			eval { $DB->DeleteTeacher($Teacher->{TeacherID}); };
		}
		foreach my $Teacher (keys(%NewTeachers))
		{
			$DB->CreateTeacher($Teacher);
		}
	}

	my @Teachers = sort map { $_->{Name} } values(%{$DB->GetAllTeachers()});
	push(@Teachers, ("") x (NUMTEACHERS - @Teachers));

	my $HTML = "<h1>Edit Teachers</h1>
				<form method=post>
					" . $Params->Extra() . "
					<table border=1>";
	for (my $CTR = 0; $CTR < @Teachers; $CTR++)
	{
		$HTML .= "		<tr>
							<td>" . ($CTR + 1) . "</td>
							<td><input " . ($CTR == 0 ? "class=focus" : "") . " name=tmp_Teacher value='" . $Teachers[$CTR] . "'></td>
						</tr>";
	}
	$HTML .= "			<tr>
							<td colspan=2><input type=submit name=tmp_Submit value='Update'></td>
						</tr>
					</table>
				</form>";
	return $HTML;
}

sub DateToGMT ($)
{
	my ($Str) = @_;
	return undef unless $Str;
	my @Parts = split("/", $Str);
	return undef unless @Parts == 3;
	my ($Mon, $Day, $Year) = @Parts;
	$Mon--;
	$Year -= 1900;
	my $Date;
	eval { $Date = timegm(0, 0, 0, $Day, $Mon, $Year); };
	return undef if $@;
	return $Date;
}

sub AddTeacherHours ()
{
	my @Errors;
	my $Success = 0;
	if ($Params->Get("tmp_Submit"))
	{
		my $TeacherID = $Params->Get("tmp_Teacher");
		my $StartDate = DateToGMT($Params->Get("tmp_StartDate"));
		my $EndDate = DateToGMT($Params->Get("tmp_EndDate"));
		my $StartTime = $Params->Get("tmp_StartTime");
		my $EndTime = $Params->Get("tmp_EndTime");
		my %Days = map { $_, $Params->Get("tmp_" . $Day[$_]) ? 1 : 0 } 0 .. $#Day;

		push(@Errors, "No teacher specified") unless $TeacherID;
		push(@Errors, "Invalid start date") unless $StartDate;
		push(@Errors, "Invalid end date") unless $EndDate;
		push(@Errors, "End date must be after start date") unless $EndDate >= $StartDate;
		push(@Errors, "End time must be after start time") unless $EndTime >= $StartTime;
		push(@Errors, "No days of week selected") unless grep { $_ == 1 } values(%Days);

		unless (@Errors)
		{
			my @Hours;
			for (my $Date = $StartDate; $Date <= $EndDate; $Date += 86400)
			{
				my (undef, undef, undef, undef, undef, undef, $WDay, undef, undef) = gmtime($Date);
				next unless $Days{$WDay};

				my $Start = $Date + $StartTime;
				my $End = $Date + $EndTime;
				push(@Hours, { Start => $Start, End => $End });
			}

			push(@Errors, map { "New Hours " . scalar(gmtime($_->{Start})) . " - " . scalar(gmtime($_->{End})) . " conflicts with existing Hours" } grep { $DB->HasExistingHours($TeacherID, $_->{Start}, $_->{End}) } @Hours);

			unless (@Errors)
			{
				foreach my $Hour (@Hours)
				{
					$DB->CreateHours($TeacherID, $Hour->{Start}, $Hour->{End});
				}
				$Success = 1;
			}
		}
	}
	else
	{
		my (undef, undef, undef, $Day, $Mon, $Year, undef, undef) = localtime();
		$Mon++;
		$Year += 1900;
		my $Date = "$Mon/$Day/$Year";
		my $Time = 28800;
		$Params->Set("tmp_StartDate=$Date", "tmp_EndDate=$Date", "tmp_StartTime=$Time", "tmp_EndTime=$Time");
	}

	my @Teachers = sort { $a->{Name} cmp $b->{Name} } values(%{$DB->GetAllTeachers()});
	unshift(@Teachers, { Name => "", TeacherID => 0 });
	my @Hours = map { { Time => $_, Display => GetPrintHM($_) } } map { $_ * LESSONTIME } 0 .. (86400 / LESSONTIME - 1);
	my $Split = 28799; # 1 Sec before 08:00 AM
	@Hours = sort { (($Split <=> $a->{Time}) <=> ($Split <=> $b->{Time})) || ($a->{Time} <=> $b->{Time}) } @Hours;
	return "<h1>Add Teacher Hours</h1>
			<form method=post>
				" . ($Success ? "Hours have been added." : "") . "
				" . $Params->Extra() . "
				" . (@Errors ? "
				" . join("<br>", "Errors:", @Errors) . "
				" : "") . "
				<table border=1>
					<tr>
						<td>Teacher</td>
						<td>
							<select class=focus name=tmp_Teacher>
								" . join("", map { "
								<option value=" . $_->{TeacherID} . ($_->{TeacherID} == $Params->Get("tmp_Teacher") ? " selected='selected'" : "") . ">" . $_->{Name} . "</Option>
								" } @Teachers) . "
							</select>
						</td>
					</tr>
					<tr>
						<td>Start date</td>
						<td><input name=tmp_StartDate class='datepicker' value='" . $Params->Get("tmp_StartDate") . "'></td>
					</tr>
					<tr>
						<td>End date</td>
						<td><input name=tmp_EndDate class='datepicker' value='" . $Params->Get("tmp_EndDate") . "'></td>
					</tr>
					<tr>
						<td>Days of week</td>
						<td>" . join("", map { "<input type=checkbox name=tmp_$_" . ($Params->Get("tmp_$_") ? " checked" : "") . ">$_<br>" } @Day) . "</td>
					</tr>
					<tr>
						<td>Start time</td>
						<td>
							<select name=tmp_StartTime>
								" . join("", map { "
								<Option value=" . $_->{Time} . ($_->{Time} == $Params->Get("tmp_StartTime") ? " selected='selected'" : "") . ">" . $_->{Display} . "</Option>
								" } @Hours) . "
							</select>
						</td>
					</tr>
					<tr>
						<td>End time</td>
						<td>
							<select name=tmp_EndTime>
								" . join("", map { "
								<Option value=" . $_->{Time} . ($_->{Time} == $Params->Get("tmp_EndTime") ? " selected='selected'" : "") . ">" . $_->{Display} . "</Option>
								" } @Hours) . "
							</select>
						</td>
					</tr>
					<tr>
						<td colspan=2><input type=submit name=tmp_Submit value='Submit'></td>
					</tr>
				</table>
			</form>

			<script>
				\$('.datepicker').datepicker();
			</script>";
}

sub RemoveTeacherHours ()
{
	my @Errors;
	my $Success = 0;
	if ($Params->Get("tmp_Submit"))
	{
		my $StartDate = DateToGMT($Params->Get("tmp_StartDate"));
		my $EndDate = DateToGMT($Params->Get("tmp_EndDate"));

		push(@Errors, "Invalid start date") unless $StartDate;
		push(@Errors, "Invalid end date") unless $EndDate;
		push(@Errors, "End date must be after start date") unless $EndDate >= $StartDate;

		unless (@Errors)
		{
			$DB->RemoveHours($StartDate, $EndDate + 86400);
			$Success = 1;
		}
	}
	else
	{
		my (undef, undef, undef, $Day, $Mon, $Year, undef, undef) = localtime();
		$Mon++;
		$Year += 1900;
		my $Date = "$Mon/$Day/$Year";
		$Params->Set("tmp_StartDate=$Date", "tmp_EndDate=$Date");
	}

	return "<h1>Remove Teacher Hours</h1>
			<p>All scheduled lessons will remain.</p>
			<form method=post>
				" . ($Success ? "Hours have been removed." : "") . "
				" . $Params->Extra() . "
				" . (@Errors ? "
				" . join("<br>", "Errors:", @Errors) . "
				" : "") . "
				<table border=1>
					<tr>
						<td>Start date</td>
						<td><input name=tmp_StartDate class='datepicker' value='" . $Params->Get("tmp_StartDate") . "'></td>
					</tr>
					<tr>
						<td>End date</td>
						<td><input name=tmp_EndDate class='datepicker' value='" . $Params->Get("tmp_EndDate") . "'></td>
					</tr>
					<tr>
						<td colspan=2><input type=submit name=tmp_Submit value='Submit'></td>
					</tr>
				</table>
			</form>

			<script>
				\$('.datepicker').datepicker();
			</script>";
}

sub BuyItems ()
{
	$Params->Set("tmp_Page=" . $Params->Get("Page")) unless $Params->Get("tmp_Page");

	my @Items;
	if ($Params->Get("tmp_Code"))
	{
		my $Item = $DB->GetItemByCode($Params->Get("tmp_Code"));
		push(@Items, $Item) if defined($Item);
	}

	my $business = 'onealaquatics@hotmail.com';
	$business = 'business@onealaquatics.com' if $debug;

	push(@Items, sort { $a->{Name} cmp $b->{Name} } $DB->GetNonCodeItems());
	my $CTR = 0;
	my $PayPal = PayPal->new(sandbox => $debug);
	return "<h1>Buy Lessons</h1>
            <p>Welcome to O'Neal Aquatics!   For optimal learning,  we would like to see each child every day for 2 weeks.  The lessons are 20 minutes and we have 4 instructors in the pool at times.  If you have more than one child you can look at the schedule and write them down at the same time if there are openings.</p>
            <p>You must prepay for every lesson you would like to book.  To start off, we would like to see them for 2 weeks and go from there.  Most kids require 20 lessons in a row to be solid in safety skills ( solid floating on back ie: 60 seconds, walls, steps,pancakes, falling in with clothes and toys coming to their back, kicking to the wall and rolling over, and getting themselves out of the water, going down the slide and coming to their back).</p>
            <p>After that, we will progress them on to Front and Back Crawl skills and drills.   There are 4 strokes they can learn in order to be on ours or any other swim team.  Ask the instructor how your child is doing, if they aren't coming to you with daily up-dates.  Ask the instructor where they are in their learning curve and how many lessons they need in order to go to a maintenance program.  Maintenance usually starts with cutting down to 3 days a week, to 2 days, then 1 day a week.  You will see very quickly if you are cutting too fast as children will loose the skills they have and will require another 10 day blast.</p>
            <p>We are very excited to work with your children and are committed to seeing as many children safe first and then proficient in the water learning new skills and loving the water as we do!  Call if you have any other questions. (801)796-9673.</p>
            <p>Thanks!</p>

			Please select the item you would like to buy:
			<table border=1>
				<tr>
					<th>#</th>
					<th>Name</th>
					<th>Price</th>
					<th></th>
				</tr>
				" . join("", map { "
				<tr" . (defined($_->{Code}) ? " class=coded" : "") . ">
					<td align=center>" . (defined($_->{Code}) ? $_->{Code} : ++$CTR) . "</td>
					<td>" . $_->{Name} . "</td>
					<td align=right>\$" . $_->{Price} . "</td>
					<td align=center>
						" . $PayPal->button(
								business => $business,
								item_name => $_->{Name},
								item_number => $_->{ItemID},
								amount => $_->{Price},
								undefined_quantity => 1,
								custom => $CurrentUser->{UserID},
								return => "http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}?Page=HandlePayPal",
							) . "
					</td>
				</tr>
				" } @Items) . "
				<tr>
					<td colspan=5>
						<form method=get>
							" . $Params->Extra() . "
							Or, enter the code of the item:
							<input type=hidden name=tmp_Page value='" . $Params->Get("tmp_Page") . "'>
							<input name=tmp_Code>
							<input type=submit value=Submit>
						</form>
					</td>
				</tr>
			</table>";
}

sub HandlePayPal ()
{
	return "Your transaction is being processed.  The lessons will be added to your balance when it is complete.";
}

sub HandleIPN ()
{
	my $token = "jLnYfz9EFjgg0Quw7JGQCyMvsUboOI9F3t7VVthbDFxI63n1enaRhU1DEXe";
	$token = "fAPMFSk_xNi_PTQYwFtdD2Hr5gthy3L_JInare67Lxv8wIrViZ_1mj9Ijjq" if $debug;
	my $PayPal = PayPal->new(sandbox => $debug);
	my $Result = $PayPal->pdtvalidate(
		tx => $Params->Get("txn_id"),
		at => $token,
	);
	return "Invalid payment (" . $Params->Get("txn_id") . ")" unless $Result;

	my ($Item) = values(%{$DB->GetItemsHash($Result->{item_number})});
	my $User = $DB->GetUser($Result->{custom});
	my $Quantity = $Result->{quantity};

 	return "Item prices don't match" unless $Result->{payment_gross} == $Item->{Price} * $Quantity;

	# This can only run once; txn_id must be unique; assume a failure means row already added.
	eval { $DB->CreatePurchase($User->{UserID}, LocalTimeAsGMT(), $Item->{Name} . " x $Quantity", $Item->{Price} * $Quantity, $Item->{NumLessons} * $Quantity, $Result->{txn_id}); };

	return "Success";
}

sub GetUserLessonsStats ($)
{
	my ($UserID) = @_;
	my $Purchased = $DB->GetUserLessonsPurchased($UserID);
	my $Used = $DB->GetUserLessonsUsed($UserID);
	my $Balance = $Purchased - $Used;
	return { Purchased => $Purchased, Used => $Used, Balance => $Balance };
}

sub History ()
{
	my @Purchases = map { $_->{Lessons} = $_->{NumLessons}; $_->{Desc} = $_->{Item} . ' ($' . $_->{Price} . ")"; $_; } $DB->GetUserPurchases($Params->Get("User"));
	my @Lessons = $DB->GetUserLessons($Params->Get("User"));
	my $Students = $DB->GetStudentsHash(Uniq(map { $_->{StudentID} } @Lessons));
	my $Lessons;
	foreach my $Lesson (@Lessons)
	{
		push(@{$Lessons->{$Lesson->{Time}}}, $Students->{$Lesson->{StudentID}}{Name});
	}
	@Lessons = map { { Time => $_, Lessons => -scalar(@{$Lessons->{$_}}), Desc => "Lesson: " . join(", ", sort @{$Lessons->{$_}}) } } keys(%$Lessons);
	my @List = sort { $a->{Time} <=> $b->{Time} } (@Purchases, @Lessons);

	my $Balance = 0;
	foreach my $Item (@List)
	{
		$Balance += $Item->{Lessons};
		$Item->{Balance} = $Balance;
	}

	my $CTR = 0;
	return "<h1>History</h1>
			<table border=1>
				<tr>
					<th>#</th>
					<th>Date/Time</th>
					<th>Description</th>
					<th>Lessons</th>
					<th>Balance</th>
				</tr>
				" . join("", map { "
				<tr>
					<td>" . ++$CTR . "</td>
					<td>" . GetPrintMDYHM($_->{Time}) . "</td>
					<td>" . $_->{Desc} . "</td>
					<td>" . $_->{Lessons} . "</td>
					<td>" . $_->{Balance} . "</td>
				</tr>
				" } @List) . "
			</table>

			" . ($CurrentUser->{Admin} ? $Params->A("Add adjustment", "Page=AddAdjustment") . "<br>" : "");
}

sub EditProfile ()
{
	my @Errors;
	my ($User) = values(%{$DB->GetUsersHash($Params->Get("User"))});

	if ($Params->Get("tmp_Register") eq "Submit")
	{
		push(@Errors, "No name given") unless $Params->Get("tmp_Name");
		my $EmailRE = qr(^[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$)i;
		push(@Errors, "Invalid email address") unless $Params->Get("tmp_Email") =~ $EmailRE;
		if ($Params->Get("tmp_Password"))
		{
			push(@Errors, "Password too short (must be at least 6 chars)") unless length($Params->Get("tmp_Password")) >= 6;
			push(@Errors, "Passwords don't match") unless $Params->Get("tmp_Password") eq $Params->Get("tmp_Confirm");
		}
		my $Phone = $Params->Get("tmp_Phone");
		$Phone =~ s/[^0-9]//g;
		my $PhoneValid = $Phone =~ /^\d{10}$/;
		if ($PhoneValid)
		{
			$Phone =~ s/(\d{3})(\d{3})(\d{4})/$1-$2-$3/;
			$Params->Set("tmp_Phone=$Phone");
		}
		push(@Errors, "Invalid phone number") unless $PhoneValid;

		if (!@Errors)
		{
			my $Checksum = "";
			$Checksum = md5_hex(join("-", SALTSTR, $Params->Get("tmp_Email"), $Params->Get("tmp_Password"))) if $Params->Get("tmp_Password");
			$DB->UpdateUser($User->{UserID}, $Params->Get("tmp_Name"), $Params->Get("tmp_Email"), $Params->Get("tmp_Password"), $Params->Get("tmp_Phone"), $Checksum);
			return LoginRedirect($Checksum, $Params->ToStr("-Page")) if ($Checksum) && (!$CurrentUser->{Admin});
			return "<script>
						\$(location).attr('search', '" . $Params->ToStr("-Page") . "');
					</script>";
		}
	}
	else
	{
		foreach my $Var ("Name", "Email", "Phone")
		{
			$Params->Set("tmp_$Var=" . $User->{$Var});
		}
	}

	return "<h1>Edit Profile</h1>
			<form method=post>
				" . $Params->Extra() . "
				" . (@Errors ? "<div id=errors>" . join("<br>", "Error:", @Errors) . "</div>" : "") . "
				<table>
					<tr>
						<td>First & Last Name:</td>
						<td><input class=focus name=tmp_Name value='" . $Params->Get("tmp_Name") . "' size=30></td>
					</tr>
					<tr>
						<td>Email:</td>
						<td><input name=tmp_Email value='" . $Params->Get("tmp_Email") . "' size=30></td>
					</tr>
					<tr>
						<td>Password:</td>
						<td><input type=password name=tmp_Password size=30></td>
					</tr>
					<tr>
						<td>Confirm Password:</td>
						<td><input type=password name=tmp_Confirm size=30></td>
					</tr>
					<tr>
						<td>Phone:</td>
						<td><input name=tmp_Phone value='" . $Params->Get("tmp_Phone") . "' size=30></td>
					</tr>
					<tr>
						<td></td>
						<td align=right><input type=submit name=tmp_Register value='Submit' size=30></td>
					</tr>
				</table>
			</form>";
}

sub AddAdjustment ()
{
	my @Errors;
	if ($Params->Get("tmp_Submit"))
	{
		push(@Errors, "Please provide a reason for this adjustment") unless $Params->Get("tmp_Item");
		push(@Errors, "Invalid price") unless $Params->Get("tmp_Price") =~ /^[-0-9.]+$/;
		push(@Errors, "Invalid num Lessons") unless $Params->Get("tmp_NumLessons") =~ /^[-0-9.]+$/;

		unless (@Errors)
		{
			$DB->CreatePurchase($Params->Get("User"), LocalTimeAsGMT(), $Params->Get("tmp_Item"), $Params->Get("tmp_Price"), $Params->Get("tmp_NumLessons"), undef);
			return "Adjustment made.  " . $Params->A("Go back", "Page=History");
		}
	}
	else
	{
		$Params->Set("tmp_Item=Adjustment", "tmp_Price=0", "tmp_NumLessons=0");
	}

	return "<form>
				" . $Params->Extra() . "
				" . (@Errors ? join("<br>", "Errors:", @Errors) : "") . "
				<table>
					<tr>
						<td>Reason for adjustment</td>
						<td><input name=tmp_Item value='" . $Params->Get("tmp_Item") . "'></td>
					</tr>
					<tr>
						<td>Price</td>
						<td><input name=tmp_Price value='" . $Params->Get("tmp_Price") . "'></td>
					</tr>
					<tr>
						<td>NumLessons</td>
						<td><input name=tmp_NumLessons value='" . $Params->Get("tmp_NumLessons") . "'></td>
					</tr>
					<tr>
						<td colspan=2><input type=submit name=tmp_Submit value='Submit'></td>
					</tr>
				</table>
			</form>";
}

sub ChangeUser ()
{
	my @Users = sort { lc($a->{Name}) cmp lc($b->{Name}) } $DB->GetAllUsers();
	return "<h1>Change Current User</h1>" . join("<br>", map { $Params->A($_->{Name} . " (" . $_->{Email} . ")", "User=" . $_->{UserID}, "-Page") } @Users);
}

sub LoginCurrentUser ()
{
	my ($User) = values(%{$DB->GetUsersHash($Params->Get("User"))});
	LoginRedirect($User->{Checksum}, $Params->ToStr("-Page"))
}

sub CombineAccounts ()
{
	my @Users = sort { lc($a->{Name}) cmp lc($b->{Name}) } $DB->GetAllUsers();

	if ($Params->Get("tmp_SubmitMap"))
	{
		return "Invalid student mapping." if scalar(grep { $_ eq "" } $Params->Get("tmp_StudentMap"));
		my $To = $Params->Get("tmp_MainAccount");
		my $From = $Params->Get("tmp_DuplicateAccount");
		my $StudentMap = { map { split("-") } $Params->Get("tmp_StudentMap") };

		$DB->CombineUsers($From, $To, $StudentMap);
		return "Done.";
	}

	if ($Params->Get("tmp_Submit"))
	{
		my $To = (grep { $_->{UserID} == $Params->Get("tmp_MainAccount") } @Users)[0];
		my $From = (grep { $_->{UserID} == $Params->Get("tmp_DuplicateAccount") } @Users)[0];
		my $ToStudents = $DB->GetUserStudents($To->{UserID});
		my $FromStudents = $DB->GetUserStudents($From->{UserID});

		$Params->Set("tmp_MainAccount=" . $Params->Get("tmp_MainAccount"));

		return "<form method=get>
					" . $Params->Extra("tmp_MainAccount=" . $Params->Get("tmp_MainAccount"), "tmp_DuplicateAccount=" . $Params->Get("tmp_DuplicateAccount")) . "
					<table>
						<tr>
							<td colspan=2>Transferring from " . $From->{Name} . " to " . $To->{Name} . ".</td>
						</tr>
						<tr>
							<td>Old Student</td>
							<td>New Student</td>
						</tr>
 						" . join("", map { my $FromStudent = $_; "
 						<tr>
							<td>" . $FromStudent->{Name} . "</td>
							<td>
								<select name=tmp_StudentMap>
									<option></option>
									" . join("", map { "<option value='" . $FromStudent->{StudentID} . "-" . $_->{StudentID} . "'>" . $_->{Name} . "</option>" } values(%$ToStudents)) . "
								</select>
							</td>
 						</tr>
 						" } values(%$FromStudents)) . "
 						<tr>
							<td colspan=2><input type=submit name=tmp_SubmitMap Value='Submit'/></td>
 						</tr>
					</table>
				</form>";

		return DoDumper($ToStudents, $FromStudents);
	}

	my @DupName = $DB->{dbh}->GetRows("SELECT Name FROM User u1 JOIN User u2 USING (Name) WHERE u1.UserID < u2.UserID ORDER BY Name");
	my @DupPhone = $DB->{dbh}->GetRows("SELECT u1.Name, u2.Name, Phone FROM User u1 JOIN User u2 USING (Phone) WHERE Phone != '000-000-0000' AND u1.UserID < u2.UserID ORDER BY Phone");
	my @DupAllChildren = $DB->{dbh}->GetRows("SELECT u1.Name, u2.Name, Names FROM (SELECT UserID, GROUP_CONCAT(Name ORDER BY Name) Names FROM Student GROUP BY UserID) sq1 JOIN (SELECT UserID, GROUP_CONCAT(Name ORDER BY Name) Names FROM Student GROUP BY UserID) sq2 USING (Names) JOIN User u1 ON u1.UserID = sq1.UserID JOIN User u2 ON u2.UserID = sq2.UserID WHERE sq1.UserID < sq2.UserID ORDER BY Names");
	my @DupSomeChildren = $DB->{dbh}->GetRows("SELECT u1.Name, u2.Name, Names FROM (SELECT s1.UserID UserID1, s2.UserID UserID2, GROUP_CONCAT(Name ORDER BY Name) Names, COUNT(*) UseCount FROM Student s1 JOIN Student s2 USING (Name) WHERE s1.UserID != 286 AND s2.UserID != 286 AND s1.UserID < s2.UserID GROUP BY UserID1, UserID2) sq1 LEFT JOIN User u1 ON u1.UserID = UserID1 LEFT JOIN User u2 ON u2.UserID = UserID2 WHERE UseCount > 1 ORDER BY Names");

	return "<form method=get>
				" . $Params->Extra() . "
				<table>
					<tr>
						<td>Main Account:</td>
						<td>
							<select name=tmp_MainAccount>
								" . join("", map { "<option value=" . $_->{UserID} . ">" . $_->{Name} . " (" . $_->{Email} . ", " . $_->{Phone} . ")</option>" } @Users) . "
							</select>
						</td>
					</tr>
					<tr>
						<td>Duplicate Account:</td>
						<td>
							<select name=tmp_DuplicateAccount>
								" . join("", map { "<option value=" . $_->{UserID} . ">" . $_->{Name} . " (" . $_->{Email} . ", " . $_->{Phone} . ")</option>" } @Users) . "
							</select>
						</td>
					</tr>
					<tr>
						<td colspan=2><input type=submit name=tmp_Submit value='Submit'></td>
					</tr>
				</table>
			</form>
			<br>

			<h2>Possible duplicates:</h2>
			<table border=1>
				<tr>
					<th>Duplicate name</th>
				</tr>
				" . join("", map { "
				<tr>
					" . join("", map { "
					<td>$_</td>
					" } @$_) . "
				</tr>
				" } @DupName) . "
			</table>
			<br>

			<table border=1>
				<tr>
					<th colspan=3>Duplicate phone number</th>
				</tr>
				<tr>
					<th>User 1</th>
					<th>User 2</th>
					<th>Phone</th>
				</tr>
				" . join("", map { "
				<tr>
					" . join("", map { "
					<td>$_</td>
					" } @$_) . "
				</tr>
				" } @DupPhone) . "
			</table>
			<br>

			<table border=1>
				<tr>
					<th colspan=3>Children duplicate</th>
				</tr>
				<tr>
					<th>User 1</th>
					<th>User 2</th>
					<th>Children</th>
				</tr>
				" . join("", map { "
				<tr>
					" . join("", map { "
					<td>$_</td>
					" } @$_) . "
				</tr>
				" } @DupAllChildren) . "
			</table>
			<br>

			<table border=1>
				<tr>
					<th colspan=3>Some children duplicate</th>
				</tr>
				<tr>
					<th>User 1</th>
					<th>User 2</th>
					<th>Children</th>
				</tr>
				" . join("", map { "
				<tr>
					" . join("", map { "
					<td>$_</td>
					" } @$_) . "
				</tr>
				" } @DupSomeChildren) . "
			</table>";
}

sub AddPayPal ()
{
	return "<form action='http://$ENV{HTTP_HOST}$ENV{SCRIPT_NAME}' method=get>
				<input type=hidden name=HandleIPN>
				Paypal transaction ID (txn_id): <input name=txn_id>
			</form>"
}

sub GetMainArea ()
{
	return GetLogin() unless defined($CurrentUser);
	my $Page = $Params->Get("Page");
	$Page = "MonthlyLessons" unless $Page;
	return Logout() if $Page eq "Logout";

	$Params->Set("User=" . $CurrentUser->{UserID}) unless $Params->Get("User");
	my $UseUserID = $Params->Get("User");
	$Params->Set("User=" . $CurrentUser->{UserID}) unless ($UseUserID == $CurrentUser->{UserID}) || ($CurrentUser->{Admin});

	if ($Params->Get("tmp_Reserve"))
	{
		my $Reserve = $Params->Get("tmp_Reserve");
		my ($TeacherID, $Time, $StudentID) = split(",", $Reserve);
		$DB->LockReserve();
		my $Val = ReserveLesson($TeacherID, $Time, $StudentID);
		$DB->UnlockTables();
		return $Val;
	}

	$Page = "EditStudents" if ($Page eq "MonthlyLessons") && (!$DB->UserHasStudents($Params->Get("User"))) && (!$CurrentUser->{Admin});

	return History() if $Page eq "History";
	return EditProfile() if $Page eq "EditProfile";
	return HandlePayPal() if $Page eq "HandlePayPal";
	return BuyItems() if $Page eq "BuyItems";
	return DailyLessons() if $Page eq "DailyLessons";
	return MonthlyLessons() if $Page eq "MonthlyLessons";
	return EditStudents() if $Page eq "EditStudents";

	return "Invalid Page" unless $CurrentUser->{Admin};

	return AddAdjustment() if $Page eq "AddAdjustment";
	return EditItems() if $Page eq "EditItems";
	return EditTeachers() if $Page eq "EditTeachers";
	return AddTeacherHours() if $Page eq "AddTeacherHours";
	return RemoveTeacherHours() if $Page eq "RemoveTeacherHours";
	return ChangeUser() if $Page eq "ChangeUser";
	return LoginCurrentUser() if $Page eq "LoginCurrentUser";
	return CombineAccounts() if $Page eq "CombineAccounts";
	return AddPayPal() if $Page eq "AddPayPal";
	return "Invalid Page";
}

sub GetPage ()
{
	InitParams();
	return HandleIPN() if $ENV{QUERY_STRING} =~ /^HandleIPN/;

	InitCurrentUser();

	return "<script src='Reservation_files/jquery-1.8.3.min.js'></script>
			<script src='Reservation_files/jquery-1.3.cookie.js'></script>
			<script src='Reservation_files/jquery-ui-1.9.2.custom/js/jquery-ui-1.9.2.custom.js'></script>
			<link rel='stylesheet' href='Reservation_files/jquery-ui-1.9.2.custom/css/ui-lightness/jquery-ui-1.9.2.custom.css' />
			<link rel='stylesheet' href='Reservation_files/style.css' />

			<div id=window>
				<div id=header></div>
				<div id=content>
				<div>
					<table width=100%>
						<tr valign=top align=right>
							<td>" . $Params->A("<img src='Reservation_files/logo.png'>", "-Page") . "</td>
							<td width=100%>
								" . (defined($CurrentUser) ? "
								<div class=dropdown>
									<a class='account arrow'>" . $CurrentUser->{Name} . "</a>

									<div class=submenu>
										<ul class=root>
 											<li>" . $Params->A("Schedule Lessons", "Page=MonthlyLessons", "-Start") . "</li>
											<li>" . $Params->A("Edit Students", "Page=EditStudents") . "</li>
											<li>" . $Params->A("Buy Lessons", "Page=BuyItems") . "</li>
											<li>" . $Params->A("History", "Page=History") . "</li>
											<li>" . $Params->A("Edit Profile", "Page=EditProfile") . "</li>
											<li>" . $Params->A("Log out", "Page=Logout") . "</li>
										</ul>
									</div>
								</div>

								" . ($CurrentUser->{Admin} ? "
								<div class=dropdown>
									<a class='account arrow'>Admin</a>

									<div class=submenu>
										<ul class=root>
											<li>" . $Params->A("Edit Items for sale", "Page=EditItems") . "</li>
											<li>" . $Params->A("Edit Teachers", "Page=EditTeachers") . "</li>
											<li>" . $Params->A("Add Teacher Hours", "Page=AddTeacherHours") . "</li>
											<li>" . $Params->A("Remove Teacher Hours", "Page=RemoveTeacherHours") . "</li>
											<li>" . $Params->A("Change Current User", "Page=ChangeUser") . "</li>
											<li>" . $Params->A("Login as Current User", "Page=LoginCurrentUser") . "</li>
											<li>" . $Params->A("Combine Accounts", "Page=CombineAccounts") . "</li>
											<li>" . $Params->A("Add Missed PayPal Payment", "Page=AddPayPal") . "</li>
										</ul>
									</div>
								</div>
								" : "") . "
								<div class=dropdown>
									<a class=account href=/>Main Site</a>
								</div>
								" : "") . "
							</td>
						</tr>
					</table>
				</div>
				" . GetMainArea() . "
				</div>
				<div id=footer></div>
			</div>

			<script src='Reservation_files/reservation.js'></script>";
}

print header() . start_html(-title => "O'Neal Aquatics - Reserve a Lesson") . GetPage(), end_html();
