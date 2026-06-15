import 'package:get/get.dart';
import '../features/home/domain/models/appointment_models.dart';
import '../features/home/presentation/controllers/home_controller.dart';
import "dart:convert";
import "package:flutter/material.dart";
import "package:flutter_svg/svg.dart";
import "package:intl/intl.dart";
import "package:shared_preferences/shared_preferences.dart";
import "../config/api_config.dart";
import "../services/localization_service.dart";
import "event_detail_screen.dart";
import '../features/jobs/pages/jobs_page.dart';
import "notification_screen.dart";
import '../features/more/pages/more_page.dart';
import '../services/network_caller.dart';
import "package:http/http.dart" as http;
class HomeScreen extends StatefulWidget {
  final String? token;

  const HomeScreen({this.token, Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final HomeController _homeController = Get.put(HomeController());

  DateTime selectedDate = DateTime.now();
  int selectedTabIndex = 0;
  DateTime today = DateTime.now();

  late PageController _pageController;
  late TabController _tabController;
  late ScrollController _calendarScrollController;
  String _greeting = "Welcome!";
  String? _userName;
  String? _userImage;
  bool _isLoading = false;

  AppointmentsResponse? _appointmentsData;
  bool _isLoadingAppointments = false;
  bool _isRefreshing = false;
  bool _hasInitializedDate = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);
    _tabController = TabController(length: 4, vsync: this, initialIndex: 0);
    _calendarScrollController = ScrollController();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _pageController.hasClients) {
        setState(() {
          selectedTabIndex = _tabController.index;
        });
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    });
    _fetchUserData();
    _fetchAppointments();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  Future<void> _fetchUserData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        debugPrint("No authentication token found");
        if (!isRefresh && mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final url = Uri.parse(ApiConfig.buildUrl("/user"));

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      debugPrint("User API Response status: ${response.statusCode}");
      debugPrint("User API Response body: ${response.body}");

      if (response.statusCode == 200) {
        if (response.headers["content-type"]?.contains("application/json") ==
            true) {
          try {
            final data = json.decode(response.body) as Map<String, dynamic>;
            debugPrint("User API Parsed data: $data");

            String? updatedAtString = data["updated_at"]?.toString();
            DateTime? updatedAt;
            String greeting = "";

            if (updatedAtString != null) {
              try {
                updatedAt = DateTime.parse(updatedAtString).toLocal();
                int hour = updatedAt.hour;

                final LocalizationService localization = LocalizationService();
                if (hour >= 5 && hour < 12) {
                  greeting = localization.translate("home.goodMorning");
                } else if (hour >= 12 && hour < 17) {
                  greeting = localization.translate("home.goodAfternoon");
                } else if (hour >= 17 && hour < 21) {
                  greeting = localization.translate("home.goodEvening");
                } else {
                  greeting = localization.translate("home.goodNight");
                }
              } catch (e) {
                debugPrint("Error parsing updated_at time: $e");
                greeting = "Welcome!";
              }
            }

            if (mounted) {
              setState(() {
                _userName = data["name"]?.toString() ?? "";
                _userImage = data["profile_url"]?.toString();
                _greeting = greeting;
              });
            }
          } catch (e) {
            debugPrint("Error parsing JSON response: $e");
          }
        }
      } else {
        debugPrint("Failed to fetch user data. Status: ${response.statusCode}");
      }
    } catch (e, stack) {
      debugPrint("Error fetching user data: $e");
      debugPrint("Stack trace: $stack");
    } finally {
      if (!isRefresh && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  List<DateTime> _generateDateList() {
    final List<DateTime> dates = [];
    final DateTime startDate = today.subtract(const Duration(days: 90));
    final DateTime endDate = today.add(const Duration(days: 90));

    DateTime currentDate = startDate;
    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      dates.add(DateTime(currentDate.year, currentDate.month, currentDate.day));
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dates;
  }

  void _navigateDay(bool isNext) {
    setState(() {
      if (isNext) {
        selectedDate = selectedDate.add(const Duration(days: 1));
      } else {
        selectedDate = selectedDate.subtract(const Duration(days: 1));
      }
    });
    _scrollToSelectedDate();
    _fetchAppointments();
  }

  void _scrollToToday() {
    if (!mounted || !_calendarScrollController.hasClients) return;

    final dates = _generateDateList();
    final todayIndex = dates.indexWhere(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );

    if (todayIndex != -1) {
      final double itemWidth = 51.0;
      final double availableWidth = MediaQuery.of(context).size.width - 100;
      final double scrollPosition =
          (todayIndex * itemWidth) - (availableWidth / 2) + (itemWidth / 2);

      _calendarScrollController.animateTo(
        scrollPosition.clamp(
          0.0,
          _calendarScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToSelectedDate({bool instant = false}) {
    if (!mounted || !_calendarScrollController.hasClients) return;

    final dates = _generateDateList();
    final selectedIndex = dates.indexWhere(
      (date) =>
          date.year == selectedDate.year &&
          date.month == selectedDate.month &&
          date.day == selectedDate.day,
    );

    if (selectedIndex != -1) {
      final double itemWidth = 51.0;
      final double availableWidth = MediaQuery.of(context).size.width - 100;
      final double targetScrollPosition =
          (selectedIndex * itemWidth) - (availableWidth / 2) + (itemWidth / 2);
      final double clampedPosition = targetScrollPosition.clamp(
        0.0,
        _calendarScrollController.position.maxScrollExtent,
      );

      final double currentPosition = _calendarScrollController.offset;
      final double itemStartPosition = selectedIndex * itemWidth;
      final double itemEndPosition = itemStartPosition + itemWidth;

      final bool isVisible =
          itemStartPosition >= currentPosition &&
          itemEndPosition <= (currentPosition + availableWidth);

      if (!isVisible) {
        if (instant) {
          _calendarScrollController.jumpTo(clampedPosition);
        } else {
          _calendarScrollController.animateTo(
            clampedPosition,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    }
  }

  Future<void> _fetchAppointments({bool isRefresh = false}) async {
    await _homeController.fetchAppointments(isRefresh: isRefresh);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      selectedDate = DateTime(today.year, today.month, today.day);
    });
    _homeController.selectDate(selectedDate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });

    await Future.wait([
      _fetchUserData(isRefresh: true),
      _fetchAppointments(isRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          if (!_tabController.indexIsChanging) {
            setState(() {
              selectedTabIndex = index;
            });
            _tabController.animateTo(index);
          }
        },
        itemCount: 4,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return _buildCalendarScreen();
            case 1:
              return const JobsPage();
            case 2:
              return const NotificationScreen();
            case 3:
              return const MorePage();
            default:
              return _buildCalendarScreen();
          }
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2638), // Elegant deep navy background
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E2638).withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(36),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                ), // Makes it taller
                child: BottomNavigationBar(
                  elevation: 0,
                  currentIndex: selectedTabIndex,
                  onTap: (index) {
                    setState(() {
                      selectedTabIndex = index;
                    });

                    int currentIndex =
                        _pageController.page?.round() ?? selectedTabIndex;
                    bool isAdjacent = (index - currentIndex).abs() == 1;

                    if (isAdjacent) {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _pageController.jumpToPage(index);
                    }

                    _tabController.animateTo(index);
                  },
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: const Color(0xFF1E2638), // Matches container
                  selectedItemColor: const Color(
                    0xFFF6C844,
                  ), // Vibrant gold highlight
                  unselectedItemColor: const Color(
                    0xFF8A98A8,
                  ), // Soft grayish blue
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    height: 1.6,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        'assets/svg/calendar_icon.svg',
                        width: 26,
                        height: 26,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF8A98A8),
                          BlendMode.srcIn,
                        ),
                      ),
                      activeIcon: SvgPicture.asset(
                        'assets/svg/calendar_selected.svg',
                        width: 26,
                        height: 26,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFF6C844),
                          BlendMode.srcIn,
                        ),
                      ),
                      label: LocalizationService().translate(
                        "home.appointments",
                      ),
                    ),
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        "assets/svg/job_icon.svg",
                        width: 26,
                        height: 26,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF8A98A8),
                          BlendMode.srcIn,
                        ),
                      ),
                      activeIcon: SvgPicture.asset(
                        "assets/svg/job_selected_icon.svg",
                        width: 26,
                        height: 26,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFF6C844),
                          BlendMode.srcIn,
                        ),
                      ),
                      label: LocalizationService().translate("home.jobs"),
                    ),
                    BottomNavigationBarItem(
                      icon: SvgPicture.asset(
                        "assets/svg/notifi_icon.svg",
                        width: 26,
                        height: 26,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF8A98A8),
                          BlendMode.srcIn,
                        ),
                      ),
                      activeIcon: SvgPicture.asset(
                        "assets/svg/notifi_selected.svg",
                        width: 26,
                        height: 26,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFF6C844),
                          BlendMode.srcIn,
                        ),
                      ),
                      label: LocalizationService().translate(
                        "home.notifications",
                      ),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.menu_rounded, size: 28),
                      activeIcon: const Icon(Icons.menu_rounded, size: 28),
                      label: LocalizationService().translate("home.more"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarScreen() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4, 0.7, 1.0],
            colors: [
              Color(0xFFC7F0F9), // Light sky blue
              Color(0xFFEDF8FA), // Light transition
              Color(0xFFFCE18D), // Soft yellow transition
              Color(0xFFF4C535), // Golden yellow
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  backgroundColor: Color(0xFF06E0FB),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : RefreshIndicator(
                onRefresh: _onRefresh,
                color: Colors.black,
                backgroundColor: const Color(0xFF06E0FB),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom App Bar
                      Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 15,
                          left: 24,
                          right: 24,
                          bottom: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF35697D,
                                        ).withOpacity(0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.network(
                                      _userImage ?? "",
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/placeholder.png',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[300],
                                                      child: const Icon(
                                                        Icons.person,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'EEEE, MMM d',
                                      ).format(DateTime.now()),
                                      style: const TextStyle(
                                        color: Color(0xFF35697D),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _userName ?? "Hello!",
                                      style: const TextStyle(
                                        color: Color(0xFF1E2638),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Color(0xFF1E2638),
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Greeting Section
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 30,
                          bottom: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2638),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "You have a clear schedule ahead.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4A8B99),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // JOB SUMMARY Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "JOB SUMMARY",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF7A869A),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        "Active",
                                        "12",
                                        [
                                          const Color(0xFFD3F2FD),
                                          const Color(0xFFEEF9FF),
                                        ],
                                        const Color(0xFF35697D),
                                        Icons.play_circle_outline,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        "Accepted",
                                        "45",
                                        [
                                          const Color(0xFFD1FADF),
                                          const Color(0xFFE8FDF0),
                                        ],
                                        const Color(0xFF2E6B47),
                                        Icons.assignment_turned_in_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryCard(
                                        "Pending",
                                        "08",
                                        [
                                          const Color(0xFFFDEBB2),
                                          const Color(0xFFFDF6DE),
                                        ],
                                        const Color(0xFF8B6C20),
                                        Icons.pending_actions_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildSummaryCard(
                                        "Rejected",
                                        "03",
                                        [
                                          const Color(0xFFFEE2E2),
                                          const Color(0xFFFEF2F2),
                                        ],
                                        const Color(0xFF991B1B),
                                        Icons.cancel_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Calendar Section
                      Container(
                        margin: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 30,
                          bottom: 20,
                        ),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Calendar",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1E2638),
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedDate = DateTime(
                                            selectedDate.year,
                                            selectedDate.month - 1,
                                            1,
                                          );
                                        });
                                        _fetchAppointments();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEEF2FB),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chevron_left,
                                          size: 20,
                                          color: Color(0xFF1E2638),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedDate = DateTime(
                                            selectedDate.year,
                                            selectedDate.month + 1,
                                            1,
                                          );
                                        });
                                        _fetchAppointments();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEEF2FB),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.chevron_right,
                                          size: 20,
                                          color: Color(0xFF1E2638),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: ["S", "M", "T", "W", "T", "F", "S"]
                                  .map(
                                    (day) => SizedBox(
                                      width: 30,
                                      child: Center(
                                        child: Text(
                                          day,
                                          style: const TextStyle(
                                            color: Color(0xFF7A8CA4),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                            _buildCalendarGrid(),
                          ],
                        ),
                      ),

                      // Events Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _homeController.isLoading.value && !_homeController.isRefreshing.value
                            ? Container(
                                height: 100,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 3.0,
                                  backgroundColor: Color(0xFF06E0FB),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildEventSections(),
                              ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    List<Color> gradientColors,
    Color contentColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: contentColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: contentColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFF1E2638),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    DateTime now = selectedDate;
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    int startingWeekday = firstDayOfMonth.weekday; // 1 (Mon) to 7 (Sun)
    if (startingWeekday == 7) startingWeekday = 0; // Make Sunday 0

    List<Widget> rows = [];
    List<Widget> currentRow = [];

    for (int i = 0; i < startingWeekday; i++) {
      currentRow.add(const SizedBox(width: 32, height: 32));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      bool isSelected = day == selectedDate.day;
      currentRow.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = DateTime(now.year, now.month, day);
            });
            _homeController.selectDate(selectedDate);
            _fetchAppointments();
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF2BC41) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1E2638)
                      : const Color(0xFF387A8C),
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );

      if (currentRow.length == 7) {
        rows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: currentRow,
          ),
        );
        rows.add(const SizedBox(height: 16));
        currentRow = [];
      }
    }

    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) {
        currentRow.add(const SizedBox(width: 32, height: 32));
      }
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: currentRow,
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildCustomerDetails(Customer customer) {
    Widget buildRow(String label, String? value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$label: ",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            Expanded(
              child: Text(
                value ?? "null",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2638),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildRow("Title", customer.title),
        buildRow("Name", customer.name),
      ],
    );
  }

  Widget _buildUpNextCard(Appointment appointment) {
      String formatTime(String timeStr) {
    try {
      if (timeStr.toUpperCase().contains("AM") || timeStr.toUpperCase().contains("PM")) {
        return timeStr;
      }
      final parts = timeStr.split(":");
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minuteStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
        final minute = int.parse(minuteStr);
        final period = hour >= 12 ? "PM" : "AM";
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return "$displayHour:${minute.toString().padLeft(2, "0")} $period";
      }
    } catch (e) {}
    return timeStr;
  }

    final String timeRange =
        "${formatTime(appointment.startTime)} - ${formatTime(appointment.endTime)}";
    final String customerName =
        "Title: ${appointment.customer.title ?? 'null'}\n"
        "Name: ${appointment.customer.name ?? 'null'}\n"
        "First Name: ${appointment.customer.firstName ?? 'null'}\n"
        "Last Name: ${appointment.customer.lastName ?? 'null'}";
    final String address =
        appointment.customer.address ?? "Address not available";
    final String type = appointment.type.isNotEmpty
        ? appointment.type
        : "Deep Clean - 3BHK";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFF6C844),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SizedBox.shrink(),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F0D6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.pets,
                                size: 14,
                                color: Color(0xFF90702F),
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Dogs present",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF90702F),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Color(0xFF4A8B99),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          timeRange,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A8B99),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 20,
                            color: Color(0xFF90702F),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCustomerDetails(appointment.customer),
                                Text(
                                  address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7A869A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailScreen(
                              occurrenceId: appointment.occurrenceId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6C844),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.navigation_outlined,
                              size: 18,
                              color: Color(0xFF90702F),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Start Navigation",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF90702F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMockUpNextCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFF6C844),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            "Deep Clean - 3BHK",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E2638),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F0D6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.pets,
                                size: 14,
                                color: Color(0xFF90702F),
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Dogs present",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF90702F),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Color(0xFF4A8B99),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "10:00 AM - 1:00 PM",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A8B99),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 20,
                            color: Color(0xFF90702F),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Sarah Jenkins",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1E2638),
                                  ),
                                ),
                                Text(
                                  "123 Horizon Ave, Apt 4B",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF7A869A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6C844),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.navigation_outlined,
                            size: 18,
                            color: Color(0xFF90702F),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Start Navigation",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF90702F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaDayCard(
    DateTime date,
    String tagText,
    Color tagBgColor,
    Color tagTextColor,
    Color borderColor,
    List<Appointment> appointments,
  ) {
    final String dateStr = DateFormat("EEE dd MMM").format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2F4F7), width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: Color(0xFF90702F),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2638),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: tagBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tagText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: tagTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (appointments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "No appointments booked",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7A869A),
                            ),
                          ),
                        ),
                      )
                    else
                      ...appointments
                          .map(
                            (appt) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildAppointmentCard(appt),
                            ),
                          )
                          .toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEventSections() {
    final List<Widget> sections = [];

    Appointment? upNextAppointment;
    if (_homeController.todayAppointments.isNotEmpty) {
      upNextAppointment = _homeController.todayAppointments.first;
    }

    sections.add(
      const Text(
        "UP NEXT",
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7A869A),
          letterSpacing: 1.2,
        ),
      ),
    );
    sections.add(const SizedBox(height: 16));

    if (upNextAppointment != null) {
      sections.add(_buildUpNextCard(upNextAppointment));
    } else {
      sections.add(_buildMockUpNextCard());
    }

    sections.add(const SizedBox(height: 30));

    sections.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "UPCOMING AGENDA",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7A869A),
              letterSpacing: 1.2,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                 // Clear selection to view all
                 _homeController.clearDateSelection();
              });
            },
            child: const Text(
              "View All",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF90702F),
              ),
            ),
          ),
        ],
      ),
    );
    sections.add(const SizedBox(height: 16));

    final upcomingList = _homeController.filteredUpcoming;
    
    if (upcomingList.isEmpty) {
        sections.add(_buildNoAppointmentsCard());
    } else {
        for (final group in upcomingList) {
          try {
            final DateTime upcomingDate = DateTime.parse(group.date);
            sections.add(
              _buildAgendaDayCard(
                upcomingDate,
                "Upcoming",
                const Color(0xFFF9F0D6),
                const Color(0xFF90702F),
                const Color(0xFFF6C844),
                group.data,
              ),
            );
          } catch (e) {}
        }
    }

    sections.add(const SizedBox(height: 20));
    return sections;
  }

  Widget _buildAppointmentCard(Appointment appointment) {
      String formatTime(String timeStr) {
    try {
      if (timeStr.toUpperCase().contains("AM") || timeStr.toUpperCase().contains("PM")) {
        return timeStr;
      }
      final parts = timeStr.split(":");
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minuteStr = parts[1].replaceAll(RegExp(r'[^0-9]'), '');
        final minute = int.parse(minuteStr);
        final period = hour >= 12 ? "PM" : "AM";
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return "$displayHour:${minute.toString().padLeft(2, "0")} $period";
      }
    } catch (e) {}
    return timeStr;
  }

    final String startTimeFormatted = formatTime(appointment.startTime);
    final String endTimeFormatted = formatTime(appointment.endTime);
    final String customerName =
        "Title: ${appointment.customer.title ?? 'null'}\n"
        "Name: ${appointment.customer.name ?? 'null'}\n"
        "First Name: ${appointment.customer.firstName ?? 'null'}\n"
        "Last Name: ${appointment.customer.lastName ?? 'null'}";
    final String address =
        appointment.customer.address ?? "Address not available";
    final String type = appointment.type.isNotEmpty
        ? appointment.type
        : "Service";

    String statusText = appointment.status.replaceAll("_", " ").toUpperCase();
    Color statusBgColor = const Color(0xFFE8F5E9);
    Color statusTextColor = const Color(0xFF2E7D32);

    if (appointment.status == "cleaner_assigned") {
      statusText = LocalizationService().translate("events.active");
    } else if (appointment.status == "on_my_way") {
      statusText = LocalizationService().translate(
        "arrivalNotification.onMyWay",
      );
      statusBgColor = const Color(0xFFE3F2FD);
      statusTextColor = const Color(0xFF1565C0);
    } else if (appointment.status == "checked_in") {
      statusText = LocalizationService().translate("events.check_in");
    } else if (appointment.status == "checked_out" ||
        appointment.status == "completed") {
      statusText = appointment.status == "completed"
          ? LocalizationService().translate("events.complete")
          : LocalizationService().translate("events.check_out");
      statusBgColor = const Color(0xFFF1F5F9);
      statusTextColor = const Color(0xFF475569);
    } else if (appointment.status == "cancelled") {
      statusText = LocalizationService().translate("events.cancel");
      statusBgColor = const Color(0xFFFFEBEE);
      statusTextColor = const Color(0xFFC62828);
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                EventDetailScreen(occurrenceId: appointment.occurrenceId),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    startTimeFormatted,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2638),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "-",
                    style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    endTimeFormatted,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              width: 1,
              height: 40,
              color: const Color(0xFFE2E8F0),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildCustomerDetails(appointment.customer),
                      ),
                      const SizedBox(width: 8),
                      if (statusText != "SCHEDULED")
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: statusTextColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.6), width: 1),
      ),
      child: ClipOval(
        child: Image.asset(
          "assets/images/placeholder.png",
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE0E0E0),
              ),
              child: const Icon(
                Icons.person,
                size: 14,
                color: Color(0xFF666666),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoAppointmentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 4,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Center(
        child: Text(
          LocalizationService().translate("home.noAppointmentsBooked"),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF999999),
          ),
        ),
      ),
    );
  }
}
