package app.astra.mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * Виджет «Астры». Картинки на 7 дней вперёд рисует Flutter
 * (lib/features/home_widget/home_widget_sync.dart) и кладёт в слоты по дню
 * недели: astra_small_d1 … astra_wide_d7. Здесь выбираем слот сегодняшнего дня
 * и размер под ширину виджета. Обновления в полночь планирует Flutter.
 */
class AstraWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) render(context, appWidgetManager, id, widgetData)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        render(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    private fun render(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        data: SharedPreferences,
    ) {
        val views = RemoteViews(context.packageName, R.layout.astra_widget)

        val minWidth = manager.getAppWidgetOptions(widgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val variant = if (minWidth >= WIDE_MIN_WIDTH_DP) "wide" else "small"

        val calendar = Calendar.getInstance()
        // Слот как в Dart: понедельник = 1 … воскресенье = 7.
        val slot = ((calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7) + 1
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(calendar.time)

        val path = data.getString("astra_${variant}_d$slot", null)
        val isToday = data.getString("astra_date_d$slot", null) == today
        val bitmap = path
            ?.takeIf { isToday && File(it).exists() }
            ?.let { BitmapFactory.decodeFile(it) }

        if (bitmap != null) {
            views.setImageViewBitmap(R.id.widget_image, bitmap)
            views.setViewVisibility(R.id.widget_image, View.VISIBLE)
            views.setViewVisibility(R.id.widget_placeholder, View.GONE)
        } else {
            // Картинок на сегодня нет (приложение давно не открывали) — мягкий призыв.
            views.setViewVisibility(R.id.widget_image, View.GONE)
            views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
        }

        views.setOnClickPendingIntent(
            R.id.widget_root,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )
        manager.updateAppWidget(widgetId, views)
    }

    companion object {
        /** С какой ширины показываем широкий вариант (≈ 3+ ячейки). */
        private const val WIDE_MIN_WIDTH_DP = 220
    }
}
