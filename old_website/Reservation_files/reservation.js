$(document).ready(function()
{
	$(".account").click(function()
	{
		$(".account").toggle();
		$(this).toggle();
		$(this).parent().children(".submenu").toggle();
	});

	//Document Click
	$(document).mouseup(function()
	{
		$(".account").show();
		$(".submenu").hide();
	});

	//Mouse click on my account link
	$(".account").mouseup(function()
	{
		return false;
	});

	$(".focus").focus();
});
