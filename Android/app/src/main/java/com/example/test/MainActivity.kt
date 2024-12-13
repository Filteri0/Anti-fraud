package com.example.test

import android.os.Bundle
import com.google.android.material.bottomnavigation.BottomNavigationView
import androidx.appcompat.app.AppCompatActivity
import androidx.navigation.findNavController
import androidx.navigation.ui.AppBarConfiguration
import androidx.navigation.ui.setupActionBarWithNavController
import androidx.navigation.ui.setupWithNavController
import com.example.test.databinding.ActivityMainBinding

/**
 * MainActivity 是應用程序的主要活動，負責設置底部導航欄和導航控制器。
 */
class MainActivity : AppCompatActivity() {

    // 使用 ViewBinding 來訪問布局中的視圖
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 初始化 ViewBinding
        binding = ActivityMainBinding.inflate(layoutInflater)
        // 設置活動的內容視圖為 binding 的根視圖
        setContentView(binding.root)

        // 獲取底部導航視圖的引用
        val navView: BottomNavigationView = binding.navView

        // 查找導航主機 Fragment 的控制器
        val navController = findNavController(R.id.nav_host_fragment_activity_main)

        // 配置 AppBar
        // 將每個菜單 ID 作為一組 ID 傳遞
        val appBarConfiguration = AppBarConfiguration(
            setOf(
                R.id.nav_semantic_recognition, R.id.nav_line_id_search, R.id.nav_url_search
            )
        )

        // 設置 ActionBar 與 NavController 的聯動
        setupActionBarWithNavController(navController, appBarConfiguration)

        // 設置底部導航視圖與 NavController 的聯動
        navView.setupWithNavController(navController)
    }
}