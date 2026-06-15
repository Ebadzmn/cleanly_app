import re
import sys

def modify_home_screen(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    # 1. Add imports
    imports = """import 'package:get/get.dart';
import '../features/home/domain/models/appointment_models.dart';
import '../features/home/presentation/controllers/home_controller.dart';
"""
    # Find the first import and add our imports after it
    first_import = content.find("import")
    if first_import != -1:
        content = content[:first_import] + imports + content[first_import:]
        
    # 2. Add HomeController to state
    state_pattern = r'class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin \{'
    replacement = r'''class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final HomeController _homeController = Get.put(HomeController());
'''
    content = re.sub(state_pattern, replacement, content)

    # 3. Replace _fetchAppointments body
    fetch_pattern = r'Future<void> _fetchAppointments\(\{bool isRefresh = false\}\) async \{[\s\S]*?Future<void> _onRefresh\(\) async \{'
    fetch_replacement = '''Future<void> _fetchAppointments({bool isRefresh = false}) async {
    await _homeController.fetchAppointments(isRefresh: isRefresh);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onRefresh() async {'''
    content = re.sub(fetch_pattern, fetch_replacement, content, count=1)

    # 4. Modify Calendar grid onTap to use controller
    on_tap_pattern = r'''onTap: \(\) \{
            setState\(\(\) \{
              selectedDate = DateTime\(now\.year, now\.month, day\);
            \}\);
            _fetchAppointments\(\);
          \},'''
    on_tap_replacement = '''onTap: () {
            setState(() {
              selectedDate = DateTime(now.year, now.month, day);
            });
            _homeController.selectDate(selectedDate);
            _fetchAppointments();
          },'''
    content = re.sub(on_tap_pattern, on_tap_replacement, content)

    # 5. Modify _buildEventSections to use _homeController.filteredUpcoming
    build_events_pattern = r'List<Widget> _buildEventSections\(\) \{[\s\S]*?return sections;\n  \}'
    
    new_build_events = '''List<Widget> _buildEventSections() {
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
  }'''
    
    content = re.sub(build_events_pattern, new_build_events, content)

    # Replace _isLoadingAppointments with _homeController.isLoading.value
    content = content.replace('_isLoadingAppointments && !_isRefreshing', '_homeController.isLoading.value && !_homeController.isRefreshing.value')

    with open(file_path, 'w') as f:
        f.write(content)

if __name__ == "__main__":
    modify_home_screen(sys.argv[1])
