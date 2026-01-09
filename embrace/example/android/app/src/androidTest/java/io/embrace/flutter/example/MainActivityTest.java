package io.embrace.flutter.example;
import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;
import io.embrace.flutter.example.MainActivity;

@RunWith(FlutterTestRunner.class)
public class MainActivityTest 
{
    @Rule
    public ActivityTestRule<MainActivity> rule = new ActivityTestRule<>(MainActivity.class, true, false);
}