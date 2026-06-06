package com.p2bble.haru_1min

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class HaruWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, widgetId: Int) {
            val prefs = HomeWidgetPlugin.getData(context)
            val waterAmount = prefs.getInt("water_amount", 0)
            val waterGoal = prefs.getInt("water_goal", 2000)
            val supplementTaken = prefs.getInt("supplement_taken", 0)
            val supplementTotal = prefs.getInt("supplement_total", 0)
            val cupSize = prefs.getInt("cup_size", 250)

            val percent = if (waterGoal > 0) (waterAmount * 100 / waterGoal).coerceAtMost(100) else 0
            val today = SimpleDateFormat("M/d (EEE)", Locale.KOREAN).format(Date())

            val views = RemoteViews(context.packageName, R.layout.haru_widget)

            views.setTextViewText(R.id.widget_date, today)
            views.setTextViewText(R.id.widget_water_text, "${waterAmount}ml / ${waterGoal}ml")
            views.setTextViewText(R.id.widget_water_percent, "$percent%")
            views.setProgressBar(R.id.widget_water_progress, 100, percent, false)
            views.setTextViewText(
                R.id.widget_supplement_text,
                if (supplementTotal == 0) "등록된 영양제 없음"
                else "영양제 $supplementTaken / $supplementTotal 완료"
            )

            // 물 추가 버튼 → Flutter background callback
            val addWaterUri = Uri.parse("homeWidget://add_water?cup_size=$cupSize")
            val addWaterPending = HomeWidgetBackgroundIntent.getBroadcast(
                context, addWaterUri
            )
            views.setOnClickPendingIntent(R.id.widget_add_water_btn, addWaterPending)

            // 위젯 탭 → 앱 열기 (home_widget launch intent)
            val launchUri = Uri.parse("homeWidget://open")
            val launchPending = HomeWidgetBackgroundIntent.getBroadcast(context, launchUri)
            views.setOnClickPendingIntent(R.id.widget_date, launchPending)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
